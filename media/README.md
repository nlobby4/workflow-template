# media/

This folder is reserved for repository-owned media assets, such as screenshots,
diagrams, generated images, and other binary files used by documentation or
project pages.

Binary assets in this folder are tracked with Git LFS. The repository stores
small pointer files in Git history, while the actual asset content is stored in
Git LFS remote storage.

Markdown files in this folder are intentionally excluded from Git LFS so they
remain readable, reviewable, and diff-able in normal Git history.

Adding the rules to `.gitattributes` affects new files from that point forward.
Existing files are not migrated automatically; move pre-existing large files to
Git LFS intentionally before committing the change.
