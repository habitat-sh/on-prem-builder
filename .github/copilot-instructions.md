# GitHub Copilot Instructions for on-prem-builder

## Repository Overview

This repository contains the Chef Habitat On-Prem Builder, which allows you to host your own private Habitat packages and manage your own origins on-premises.

### Repository Structure

```
on-prem-builder/
├── .github/                          # GitHub workflows and configurations
│   └── workflows/                    # CI/CD pipeline definitions
├── docs-chef-io/                     # Hugo-based documentation
│   ├── config.toml                   # Hugo configuration
│   ├── go.mod                        # Go module for docs
│   ├── content/habitat/on_prem_builder/  # Documentation content
│   │   ├── _index.md                 # Main documentation index
│   │   ├── troubleshooting.md        # Troubleshooting guide
│   │   ├── configure/                # Configuration guides
│   │   ├── install/                  # Installation guides
│   │   ├── manage/                   # Management guides
│   │   ├── origins/                  # Origin management docs
│   │   └── packages/                 # Package management docs
│   └── static/images/                # Static assets for documentation
├── package_seed_lists/               # Package seed lists for bootstrapping
│   ├── README.md                     # Seed lists documentation
│   └── *.stable                      # Various package seed files
├── pkg-sync/                         # Package synchronization tool
│   ├── main.go                       # Go source code
│   ├── plan.sh                       # Habitat plan file
│   └── README.md                     # Tool documentation
├── pkg-tool/                         # Package analysis tool
│   ├── main.go                       # Go source code
│   ├── plan.sh                       # Habitat plan file
│   ├── build.sh                      # Build script
│   └── README.md                     # Tool documentation
├── scripts/                          # Installation and utility scripts
│   ├── hab-sup.service.sh            # Habitat supervisor service
│   ├── install-hab.sh                # Habitat installation script
│   ├── on-prem-archive.sh            # Archive creation script
│   └── provision.sh                  # Provisioning script
├── terraform/                        # Infrastructure as Code
│   ├── README.md                     # Terraform documentation
│   ├── aws/                          # AWS deployment templates
│   ├── digitalocean/                 # DigitalOcean deployment templates
│   └── templates/                    # Common templates
├── bldr.env.sample                   # Sample environment configuration
├── install.sh                        # Main installation script
├── uninstall.sh                      # Uninstallation script
├── README.md                         # Main project documentation
├── CHANGELOG.md                      # Change log
├── LICENSE                           # License information
└── VERSION                           # Current version
```

## Critical Instructions

### File Modification Restrictions

**IMPORTANT**: Do not modify `*.codegen.go` files if they are present in the repository. These files are automatically generated and manual modifications will be overwritten.

### Testing Requirements

- **Unit Test Coverage**: Always create comprehensive unit test cases for any implementation
- **Coverage Threshold**: The test coverage of the repository must always be maintained above 80%
- **Test Files**: Place test files adjacent to the source files following Go conventions (e.g., `main_test.go` for `main.go`)
- **Test Commands**: Use `go test -v ./...` for running all tests and `go test -cover ./...` for coverage reports

### MCP Server Integration

When a Jira ID is provided in the task:
1. Use the atlassian-mcp-server MCP server to fetch Jira issue details
2. Read the story description, acceptance criteria, and requirements carefully
3. Implement the task according to the specifications in the Jira ticket
4. Ensure all requirements and edge cases mentioned in the ticket are addressed

### Workflow Requirements

All tasks must be performed in a prompt-based manner:
1. **Step-by-step execution**: Complete one step at a time
2. **Progress reporting**: After each step, provide a summary of what was completed
3. **Next step preview**: Clearly state what the next step will be
4. **Remaining tasks**: List all remaining steps to be completed
5. **User confirmation**: Ask if the user wants to continue with the next step before proceeding

## Pull Request Creation Workflow

When prompted to create a PR for changes:

1. **Branch Creation**: Create a new branch using the Jira ID as the branch name
   ```bash
   git checkout -b <JIRA-ID>
   ```

2. **Commit Changes**: Stage and commit all changes with a descriptive message
   ```bash
   git add .
   git commit -m "feat: <brief description of changes> - <JIRA-ID>"
   ```

3. **Push Branch**: Push the changes to the remote repository
   ```bash
   git push origin <JIRA-ID>
   ```

4. **Create PR**: Use GitHub CLI to create the pull request
   ```bash
   gh pr create --title "<JIRA-ID>: <descriptive title>" --body "<PR_DESCRIPTION>" --head <JIRA-ID>
   ```

5. **Add Label**: Add the required test label to the PR
   ```bash
   gh pr edit <JIRA-ID> --add-label "runtest:all:stable"
   ```

### PR Description Format

The PR description must be formatted using HTML tags and should include:

```html
<h2>Summary</h2>
<p>Brief description of the changes made</p>

<h2>Changes Made</h2>
<ul>
  <li>Change 1</li>
  <li>Change 2</li>
  <li>Change 3</li>
</ul>

<h2>Jira Ticket</h2>
<p><a href="https://your-jira-instance.atlassian.net/browse/<JIRA-ID>"><JIRA-ID></a></p>

<h2>Testing</h2>
<ul>
  <li>Unit tests added/updated</li>
  <li>Coverage maintained above 80%</li>
  <li>All existing tests pass</li>
</ul>

<h2>Checklist</h2>
<ul>
  <li>[ ] Code follows project standards</li>
  <li>[ ] Tests added and passing</li>
  <li>[ ] Documentation updated if needed</li>
  <li>[ ] No breaking changes introduced</li>
</ul>
```

## Complete Implementation Workflow

When implementing a task, follow this comprehensive workflow:

### Phase 1: Planning and Analysis
1. **Requirement Analysis**: Read and understand the task requirements
2. **Jira Integration**: If Jira ID provided, fetch and analyze ticket details using atlassian-mcp-server
3. **Impact Assessment**: Identify all files that need to be modified
4. **Test Strategy**: Plan what tests need to be created or modified
5. **Ask for Continuation**: Confirm with user before proceeding

### Phase 2: Implementation
1. **Code Implementation**: Write the required functionality
2. **Follow Standards**: Ensure code follows Go conventions and project patterns
3. **Error Handling**: Implement proper error handling and validation
4. **Documentation**: Add inline comments for complex logic
5. **Ask for Continuation**: Confirm with user before proceeding

### Phase 3: Testing
1. **Unit Tests**: Create comprehensive unit tests for new functionality
2. **Test Existing**: Ensure all existing tests still pass
3. **Coverage Check**: Verify coverage remains above 80%
4. **Integration Tests**: Add integration tests if needed
5. **Ask for Continuation**: Confirm with user before proceeding

### Phase 4: Documentation
1. **Code Documentation**: Update inline documentation
2. **README Updates**: Update relevant README files if functionality changes
3. **API Documentation**: Update API docs if new endpoints or methods added
4. **Usage Examples**: Add examples if new features are introduced
5. **Ask for Continuation**: Confirm with user before proceeding

### Phase 5: Quality Assurance
1. **Code Review**: Self-review the implementation
2. **Security Check**: Verify no security vulnerabilities introduced
3. **Performance Check**: Ensure no performance regressions
4. **Compatibility Check**: Verify backward compatibility maintained
5. **Ask for Continuation**: Confirm with user before proceeding

### Phase 6: Git Operations and PR Creation
1. **Branch Creation**: Create feature branch with Jira ID as name
2. **Commit Changes**: Commit with descriptive messages
3. **Push Branch**: Push to remote repository
4. **Create PR**: Use GitHub CLI to create pull request
5. **Add Labels**: Add "runtest:all:stable" label
6. **Final Summary**: Provide complete summary of all changes made

## Project-Specific Guidelines

### Go Development Standards
- Follow Go conventions for naming, structure, and documentation
- Use proper error handling with meaningful error messages
- Implement interfaces where appropriate for testability
- Use dependency injection for external dependencies

### Habitat Package Management
- Understand Habitat plan files (`plan.sh`) and their structure
- Respect Habitat package lifecycle and dependencies
- Use proper Habitat service configuration patterns

### Configuration Management
- Use environment variables from `bldr.env` for configuration
- Maintain backward compatibility with existing configurations
- Validate configuration values and provide meaningful error messages

### Security Considerations
- Never commit sensitive information like keys or passwords
- Use secure defaults for all configurations
- Implement proper authentication and authorization checks
- Validate all user inputs to prevent injection attacks

## Documentation Standards

### Code Comments
- Add package-level documentation for all packages
- Document all exported functions, types, and variables
- Include examples in documentation where helpful
- Use proper Go doc format

### README Updates
- Keep README files current with functionality changes
- Include usage examples for new features
- Update installation and setup instructions as needed
- Maintain clear and concise documentation

## Prohibited Actions

1. **Do not modify** `*.codegen.go` files
2. **Do not commit** sensitive information (keys, passwords, tokens)
3. **Do not break** existing APIs without proper deprecation
4. **Do not skip** test creation for new functionality
5. **Do not merge** without proper code review process
6. **Do not ignore** test failures or coverage drops

## Success Criteria

Before considering any task complete:
- [ ] All requirements from Jira ticket (if provided) are implemented
- [ ] Unit tests are created and passing
- [ ] Test coverage is above 80%
- [ ] All existing tests continue to pass
- [ ] Code follows project conventions and standards
- [ ] Documentation is updated where necessary
- [ ] No security vulnerabilities introduced
- [ ] Changes are committed with descriptive messages
- [ ] Pull request is created with proper description and labels
- [ ] User has confirmed completion of each phase

## Notes

- All tasks are performed on the local repository
- Use the atlassian-mcp-server for Jira integration when Jira IDs are provided
- Always ask for user confirmation before proceeding to the next step
- Provide detailed summaries after each completed step
- Maintain clear communication about progress and remaining tasks