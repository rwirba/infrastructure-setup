# Jenkins Slave

Ubuntu-based Jenkins agent with:
- Docker CLI
- OpenJDK 11
- Maven
- Ansible
- SSH pre-installed

### Usage:
Connect via JNLP or SSH from Jenkins master.
```yaml
clouds:
  - kubernetes:
      templates:
        - name: "ubuntu-agent"
          image: yourregistry/jenkins-slave:latest
```

Slave registers automatically and runs pipeline builds.
```

---