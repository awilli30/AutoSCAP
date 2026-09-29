# AutoSCAP
Script to make running OpenSCAP scans simple.

🚀 Introducing AutoSCAP 🔒
If you’ve ever had to run security compliance scans with OpenSCAP, you know the drill: digging through documentation, copy-pasting long CLI commands, and trying to memorize cryptically named profile IDs.
To make life easier for DevSecOps professionals, sysadmins, and security practitioners, I built AutoSCAP—a lightweight tool written entirely in Bash that automates the entire OpenSCAP workflow.
💡 How AutoSCAP Simplifies Your Security Scans:
* No More Long Commands: Say goodbye to complex flags and path arguments. Run comprehensive scans with simple, intuitive execution.
* No Profile ID Memorization: Easily select or target compliance profiles without hunting down long string identifiers every single time.

By removing the friction and cognitive load from running security audits, AutoSCAP helps practitioners focus on what actually matters: remediating vulnerabilities and keeping systems secure.

**NOTE: OpenSCAP needs to be downloaded before using AutoSCAP**
***Command to get OpenSCAP: sudo dnf install openscap-scanner scap-security-guide***

curl -0 https://raw.githubusercontent.com/awilli30/AutoSCAP/refs/heads/main/autoscap.sh
