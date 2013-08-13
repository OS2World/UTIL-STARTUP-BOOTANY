********************************************************************************

    This program uses methods different than those documented by FDISK
    to boot your computer. You should read the following text to
    understand how BOOTANY works and what it will do for you.

********************************************************************************


This package consists of the following files:

   BOOTANY      - The NMAKE file for BOOTANY.SYS
   BOOTANY.ASM  - The source code to an assembler program which can be
                  used as a replacement for the master boot program on
                  hard disks with multiple partitions.
   BOOTANY.SYS  - The binary image used as the new master boot program.
   BOOTANY.H    - Definitions and structures used by the C programs.
   BOOTANY.INC  - Definitions and equates used by BOOTANY.ASM and
                  BSTRAP.ASM
   BOOTIO.ASM   - The source for the program which reads or writes the
                  Master Boot Record.
   BSTRAP       - The NMAKE file for BSTRAP.COM
   BSTRAP.ASM   - The source for the program which installs BOOTANY.SYS
                  onto your hard disk.
   BSTRAP.COM   - The executable file which will install BOOTANY.SYS
   INSTBOOT.BAT - A batch file which when executed installs BOOTANY.SYS
                  on your hard disk.
   PREFDISK     - The NMAKE file for PREFDISK.EXE
   PREFDISK.C   - The source for the program to run before FDISK.
   PREFDISK.EXE - Program to invalidate partition table entries before
                  running FDISK.
   PREINST      - The NMAKE file for PREINST.EXE
   PREINST.C    - The source for the program to validate all partition
                  Table entries
   PREINST.EXE  - Program to validate all partition table entries before
                  Running BSTRAP
   READ.ME      - This file
   SHOWBOOT     - The NMAKE file for SHOWBOOT.EXE
   SHOWBOOT.C   - The source for the program which displays the master
                  partition table
   SHOWBOOT.EXE - Program to display the master partition table



Section 1 - How the ROM BIOS Boots an Operating System

When an IBM PC or compatible computer boots (via <CTRL><ALT><DEL> or
by turning the power on), the last operation the ROM BIOS boot strap
program does is to read the first sector of the A: drive or if no disk
is present in A:, the first sector of the C: drive. After the sector is
read to the 512 bytes starting at address 0000:7C00, the boot strap
program validates the sector by insuring that the last 2 bytes
(0000:7DFE) contain the hex value 55AA. If they are, the boot strap
program branches to 0000:7C00. It is important to note that up until
this point NO operating system services have been created or are
available. This is why some programs (like Flight Simulator) can be
started at system boot, and also why the PC is capable of running
multiple operating systems.


Section 2 - The Master Boot Record

On a floppy diskette formatted with the DOS command "FORMAT A: /s",
the first sector will contain EB34xx in the first three bytes. This
is a jump instruction which bypasses the next several bytes. Following
this will be an 8 character system id. On machines using IBM DOS this
will be the characters "IBM " followed by the version of DOS. And
of course the last two bytes of the sector will contain hex 55AA. This
is the DOS boot program.

On hard disks, which must be set up with FDISK, other than the last
two bytes containing hex 55AA and the first byte containing an
executable instruction, this first sector is quite different. It is
called the Master Boot Record.

Starting at byte 446 (hex 1BE) is the Partition Table. It contains
4 entries, so your hard disk can be divided into at most 4 partitions.
Each entry has the following format:

Offset   Size   Field              Purpose
+0         1    BootIndicator      Indicates if partition is startable
                  hex 00             Non-startable partition
                  hex 80             Startable partition
+1         1    BeginHead          Side on which partition starts
+2         1    BeginSector        Sector at which partition starts
+3         1    BeginCyl           Cylinder at which partition starts
+4         1    SystemId           Identifies partition type
                  hex 00             Empty partition entry
                  hex 01             DOS FAT-12
                  hex 02             XENIX
                  hex 04             DOS FAT-16
                  hex 05             Extended partition
                  hex 06             DOS > 32M
                  hex 07             HPFS
                  hex 64             Novell
                  hex 75             PCIX
                  hex DB             CP/M
                  hex FF             BBT
+5         1    EndHead            Side on which partition ends
+6         1    EndSector          Sector at which partition ends
+7         1    EndCyl             Cylinder at which partition ends
+8         4    RelativeSectors    # Sectors before start of partition
+12        4    NumberSectors      # Sectors in partition


The master boot program (starting at byte 0) copies itself to a
different location in memory and then inspects the partition table
looking for a startable partition. If more than one startable partition
exists or any BootIndicator is not hex 80 or 0 than "Invalid Partition
Table" will be written on the screen and the program will enter an
endless loop.  After successfully validating the table, the program then
obtains the Begin Head, Sector, and Cylinder for the startable partition
and reads it from disk to 0000:7C00. It validates that the hex 55AA is
present and then jumps to location 0000:7C00.  From this point on
startup is identical to booting from a floppy.


Section 3 - OS/2

OS/2 supports the use of multiple partitions on a hard disk just as
DOS does. In fact, FDISK is again how OS/2 partitions are defined.
What is slightly strange though, is that HPFS partitions must be
defined using FDISK as DOS primary or secondary partitions. This
means that they are initially defined as FAT partitions. However,
when OS/2 formats that partition as HPFS it updates the Partition
Table to indicate a type of 07.

During installation, OS/2 tries to install itself in the first DOS
partition it finds - even if its too small or something is already
there. If it doesn't find a DOS partition it will look for the first
HPFS and install itself there. OS/2 installation also marks the
installed OS/2 partition as the "Active" partition. The BOOT program
accompanying OS/2 1.2 changes the active partition to the OS/2 or
DOS partition. Re-booting the computer causes the appropriate
operating system to be started.


Section 3 - Multiple "Primary" partitions.

Primary partitions basically are those with system ids other than 0 or
5. A 0 system id indicates that the partition entry is not in use.  Type
5 is a special type of partition which I will discuss a little later.
Type 5 partitions cannot be marked startable.

DOS and OS/2 (and presumably other operating systems) behave similarly
with regards to how they handle multiple primary partitions. If a PC
contains multiple hard disks, each must contain a primary partition
valid for the target operating system for it to be recognized.  If both
disks also contained a secondary, after boot the drive configuration
would be:

   C: First hard disk's primary partition
   D: Second hard disk's primary partition
   E: First hard disk's secondary partition
   F: Second hard disk's secondary partition

If the primary partition on the first drive became unavailable, the
operating system could (and woould) boot off of the second drive's
primary partition. Unknown partition types are completely ignored by the
operating system so a hard disk with no known primary partition will be
skipped.

When a single drive is configured with multiple primaries similar
logic is encountered. First all unknown partitions are ignored by
the operating system. Secondly, only the first known primary and valid
secondaries become accessable.  If the following configuration were
used,

  Partition  SystemId
      1         07
      2         07
      3         06
      4         05

and a boot of OS/2 was attempted, OS/2 would mark partition 1 as C:,
ignore partitions 2 and 3, and then would look at the extended
partition for more logical drives.  If partition 2 were marked as the
startable partition some bizarre behaviour would be encountered. OS/2
would be started using the boot program from partition 2, however C:
would be partition one and partition 2 would be inaccessable, most
likely causing strange results.


Section 4 - Secondary partitions.

Secondary partitions allow the creation of DOS or HPFS partitions
which can be shared among operating systems or versions of an
operating system. For example, an extended partition may be defined
as having both an HPFS partition and a FAT partition. DOS will be
able to manipulate the FAT partititon while all versions of OS/2
can work with both the FAT and the HPFS partitions. Thus version
specific data may be kept on the primary partitions while common
data may be kept on an extended partition.

Secondary (or extended) partitions are those defined as type 5. FDISK
only allows them to be created if a primary partition is defined,
however, the available OS/2 documentation states that secondary
partitions may be created without a primary if the (phsysical) drive
is not startable.

A secondary partition contains a collection of "extended volumes"
which are linked together by a pointer in the extended volumes'
start-up record.  Each extended volume contains an extended start-up
record, located in the first sector of the volume. The extended
start-up record contains the normal 55AA signiture at the end. The
extended start-up record also contains a partition table, the format
of which is identical to the master partition table. The code in
the extended start-up record, if there is any, starts at location 0
and probably writes a message indicating an attempt to start a
non-startable partition.  A partition entry of type 5 allows chaining
to the next extended volume.

An extended volume is only allowed to have one block device driver,
therefore only 1 entry will be used to map a logical drive. One
other entry may be used to chain to the next extended volume.

Section 5 - How BOOTANY works.

BOOTANY is a fairly simple program. It has to be to fit within the
445 bytes available for code in the master boot record.

First, BOOTANY must be installed. As part of the installation, the
installer associates function keys 1, 2, and/or 3 with a specific entry
in the partition table and a short description of the partition.  As
each partition is defined it will be validated to insure it was marked
startable. If it was not it can be marked startable by the install
program.  Only startable partititons should be defined as primary
partitions.

After all the partitions have been defined to BOOTANY, the install
program will proceed to move the SystemId in each bootable partition
entry to the BootIndicator field in the same entry. The SystemId
will then be set to hex 80 (an undefined value). If the system
were then to be booted from a floppy, NO valid partitions would
exist.

After installation, every time the computer is rebooted from the
hard disk a short menu will appear. The menu consists of the
defined function keys along with their textual description. Whichever
function key was used at the previous boot will be displayed as the
default. If no key is depressed within 5 seconds, the default system
will be booted.

After selection of a boot partition, BOOTANY will validate that the
partition is startable (the BootIndicator is non-zero). If it is the
first sector of the partition will be read to 0000:7C00. The last two
bytes will be compared to hex 55AA. If they match, the previously booted
partition entry will be modified so that the BootIndicator contains the
SystemId value and the SystemId is hex 80.  The partition entry to be
booted will next be modified so that the System ID is restored and the
BootIndicator is set to hex 80.

This procedure insures that there is only one valid primary partition at
a time, thus avoiding the situation described in the last paragraph of
Section 3 above.


Section 6 - Installing and booting multiple operating systems.


Sample installation for OS/2 1.2, OS/2 2.0 and DOS 4.0

1. Start with an empty but low-level formatted hard disk.
2. Using DOS FDISK create a primary partition to be used by DOS 4.0 as
   its FAT C: drive. (2 Meg minimum) Make sure the partition is marked
   startable.
3. Install DOS onto drive C:
4. Run PREFDISK.EXE to invalidate the partition just created.
5. Using DOS FDISK create a DOS primary partition to be used by OS/2 1.2 as
   its HPFS C: drive. (14 Meg minimum) Make sure the partition is marked
   startable.
6. Install OS/2 onto drive C:
7. Boot DOS from floppy and again run PREFDISK to invalidate the partition
   just created.
8. Using DOS FDISK create a primary partition to be used by OS/2 2.0 as
   its HPFS C: drive. (14 Meg minimum) Make sure the partition is marked
   startable.
9. Install OS/2 onto drive C:
10.Run INSTBOOT replying as indicated: (entered text is shown in [])

<CTRL><BREAK> may be used to end the install at any time

What partition should be installed to F1? (1-3, 0 to end) [1]

Enter partition description to be assigned to F1 (15 chars max) [OS/2 1.2 HPFS]

What partition should be installed to F1? (1-3, 0 to end) [2]

Enter partition description to be assigned to F1 (15 chars max) [OS/2 2.0 HPFS]

What partition should be installed to F1? (1-3, 0 to end) [3]

Enter partition description to be assigned to F1 (15 chars max) [DOS  4.0 FAT ]

Do you want Num Lock turned off at boot? [Y]

Boot record updated.

11.Press <CTRL><ALT><DEL>

At restart the computer will respond with:

F1 . . . OS/2 1.2 HPFS
F2 . . . OS/2 2.0 HPFS
F3 . . . DOS  4.0 FAT
F4 . . . ROM BASIC

Default: F?

12.Select F3 and run FDISK to Install a secondary partition and logical FAT
and/or HPFS drives as desired.

13.Reboot the computer. The default will now be F3 since DOS was
previously booted.


To install a new operating system

1a.Boot the operating system which will have its partition entry
   changed, or
1b.Boot DOS, run PREFDISK to invalidate all partitions and then run
   FDISK to install a new partition.
2. Install the new operating system in the vacant partition.
3. Run INSTBOOT replying as needed.
4. Reboot the computer.
