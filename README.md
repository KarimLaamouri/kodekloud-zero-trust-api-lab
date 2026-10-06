## ⚙️ Methodology: From Console to CLI Automation
The original KodeKloud lab instructions utilize the AWS Management Console to build and configure the Zero-Trust architecture manually. 

To align this project with modern Site Reliability Engineering (SRE) and DevOps best practices, I took the initiative to reverse-engineer the "ClickOps" steps into programmatic commands. 

**In this repository, you will find:**
* **Reproducible Scripts:** The manual console clicks have been translated into self-contained Bash scripts using the AWS CLI.
* **Tested Execution:** Every CLI command was manually tested, debugged, and verified by me within the lab environment before being compiled into these final scripts.
* **Infrastructure as Code Mindset:** By automating the deployment, this repository demonstrates how to build security infrastructure that is version-controlled, repeatable, and scalable—moving beyond manual GUI configurations.
