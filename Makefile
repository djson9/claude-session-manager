.PHONY: install start shell-command uninstall-shell-command

install:
	@./install.sh

install-shell-command:
	@./install_shell_commands.sh

uninstall-shell-command:
	@./install_shell_commands.sh uninstall

start:
	@./session_manager.sh
