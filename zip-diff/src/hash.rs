use blake3::{Hash, Hasher};
use std::collections::HashSet;
use std::path::Path;

#[derive(Clone, Copy)]
pub enum ParsingResult {
    Ok(Hash),
    Err,
}

impl ParsingResult {
    pub fn inconsistent_with(&self, rhs: &Self) -> bool {
        match (self, rhs) {
            (ParsingResult::Ok(lhs), ParsingResult::Ok(rhs)) => lhs != rhs,
            _ => false,
        }
    }
}

pub fn read_parsing_result(path: impl AsRef<Path>, par: bool) -> ParsingResult {
    read_parsing_result_with_ignore(path, par, &HashSet::new())
}

pub fn read_parsing_result_with_ignore(
    path: impl AsRef<Path>,
    par: bool,
    ignore_names: &HashSet<Vec<u8>>,
) -> ParsingResult {
    let path = path.as_ref();
    if path.is_dir() {
        ParsingResult::Ok(
            dirhash(path, par, ignore_names).unwrap_or(Hash::from_bytes(Default::default())),
        )
    } else {
        ParsingResult::Err
    }
}

fn should_ignore_name(name: &[u8], ignore_names: &HashSet<Vec<u8>>) -> bool {
    // Exact name ignore, plus suffix ignore for patterns like ".covinfo" and ".jacoco.csv".
    ignore_names.contains(name)
        || ignore_names
            .iter()
            .any(|pat| pat.first() == Some(&b'.') && name.ends_with(pat))
}

// Returns `None` for empty directory
fn dirhash(path: impl AsRef<Path>, par: bool, ignore_names: &HashSet<Vec<u8>>) -> Option<Hash> {
    let path = path.as_ref();
    let path_display = path.display();
    let mut hasher = Hasher::new();

    if path.is_symlink() {
        hasher.update(b"L");
        hasher.update(
            &path
                .read_link()
                .unwrap_or_else(|_| panic!("failed to read link {path_display}"))
                .into_os_string()
                .into_encoded_bytes(),
        );
    } else if path.is_file() {
        hasher.update(b"F");
        if par {
            hasher.update_mmap_rayon(path)
        } else {
            hasher.update_mmap(path)
        }
        .unwrap_or_else(|_| panic!("failed to read file {path_display}"));
    } else if path.is_dir() {
        hasher.update(b"D");
        let mut children = path
            .read_dir()
            .unwrap_or_else(|_| panic!("failed to read dir {path_display}"))
            .filter_map(|entry| {
                let entry =
                    entry.unwrap_or_else(|_| panic!("failed to read dir entry in {path_display}"));
                let entry_path = entry.path();
                let mut hasher = Hasher::new();
                let name = entry.file_name().into_encoded_bytes();
                if should_ignore_name(&name, ignore_names) {
                    return None;
                }
                if name.iter().all(|x| {
                    x.is_ascii_alphanumeric() || matches!(x, b'.' | b'_' | b'-' | b'[' | b']')
                }) {
                    hasher.update(b"N");
                    hasher.update(&name);
                } else {
                    // treat all special file names as the same
                    hasher.update(b"S");
                }
                hasher.update(
                    dirhash(entry_path, par, ignore_names)? /* ignore empty dir */
                        .as_bytes(),
                );
                Some(hasher.finalize().into())
            })
            .collect::<Vec<[u8; 32]>>();
        if children.is_empty() {
            return None;
        }
        children.sort_unstable();
        for child in children {
            hasher.update(&child);
        }
    } else {
        panic!("file does not exist, permission error, or unknown file type: {path_display}");
    }

    Some(hasher.finalize())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn mk_temp_dir(prefix: &str) -> std::path::PathBuf {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("time error")
            .as_nanos();
        let dir = std::env::temp_dir().join(format!("{prefix}-{nonce}"));
        fs::create_dir_all(&dir).expect("create temp dir failed");
        dir
    }

    #[test]
    fn covinfo_suffix_is_ignored_from_hash() {
        let dir = mk_temp_dir("zipdiff-hash-ignore");
        fs::write(dir.join("ok.txt"), b"hello").expect("write ok.txt failed");
        fs::write(dir.join("a.covinfo"), b"12.3").expect("write covinfo failed");

        let mut ignore = HashSet::new();
        ignore.insert(b".covinfo".to_vec());

        let with_ignore = read_parsing_result_with_ignore(&dir, false, &ignore);

        fs::remove_file(dir.join("a.covinfo")).expect("remove covinfo failed");
        let baseline = read_parsing_result_with_ignore(&dir, false, &ignore);

        assert!(matches!((with_ignore, baseline), (ParsingResult::Ok(a), ParsingResult::Ok(b)) if a == b));
        let _ = fs::remove_dir_all(dir);
    }

    #[test]
    fn covinfo_changes_hash_without_ignore() {
        let dir = mk_temp_dir("zipdiff-hash-no-ignore");
        fs::write(dir.join("ok.txt"), b"hello").expect("write ok.txt failed");
        let empty_ignore = HashSet::new();
        let baseline = read_parsing_result_with_ignore(&dir, false, &empty_ignore);

        fs::write(dir.join("a.covinfo"), b"12.3").expect("write covinfo failed");
        let changed = read_parsing_result_with_ignore(&dir, false, &empty_ignore);

        assert!(matches!((baseline, changed), (ParsingResult::Ok(a), ParsingResult::Ok(b)) if a != b));
        let _ = fs::remove_dir_all(dir);
    }
}
