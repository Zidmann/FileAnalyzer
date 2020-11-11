# FileAnalyzer
By [Zidmann](mailto:emmanuel.zidel@gmail.com) :bow:

## Description
Script to analyze the elements in a directory (file/directory/link/...) to, in a second step, index them and compare them.
The project includes a second script to validate the report output.

## Demo
The demo was made on my personal computer by analyzing the files of the project itself.
Then the command below was simply launched in the Linux/ directory of the project :
```bash
./bat/scan_dir_files.sh .
./bat/fix_report.sh report/<PREVIOUS_REPORT_FILE>
```

## Mount
To secure the operation the external disks are mounted in read-only mode.
Since the system may try to write into the device anyway and fail, mounting the filesystem read-only can cause some trouble; consequently the 'noload' flag may be used, to notify to the system that the disk is blocked.
```bash
mount -o ro,noload /dev/<device> <directory_path>
```

