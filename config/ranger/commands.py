# This is a sample commands.py.  You can add your own commands here.
#
# Please refer to commands_full.py for all the default commands and a complete
# documentation.  Do NOT add them all here, or you may end up with defunct
# commands when upgrading ranger.

# A simple command for demonstration purposes follows.
# -----------------------------------------------------------------------------

from __future__ import (absolute_import, division, print_function)

# You can import any python module as needed.
import os

# You always need to import ranger.api.commands here to get the Command class:
from ranger.api.commands import Command

# udisk menu for ranger
from plugins.ranger_udisk_menu.mounter import mount


# Any class that is a subclass of "Command" will be integrated into ranger as a
# command.  Try typing ":my_edit<ENTER>" in ranger!
class my_edit(Command):
    # The so-called doc-string of the class will be visible in the built-in
    # help that is accessible by typing "?c" inside ranger.
    """:my_edit <filename>

    A sample command for demonstration purposes that opens a file in an editor.
    """

    # The execute method is called when you run this command in ranger.
    def execute(self):
        # self.arg(1) is the first (space-separated) argument to the function.
        # This way you can write ":my_edit somefilename<ENTER>".
        if self.arg(1):
            # self.rest(1) contains self.arg(1) and everything that follows
            target_filename = self.rest(1)
        else:
            # self.fm is a ranger.core.filemanager.FileManager object and gives
            # you access to internals of ranger.
            # self.fm.thisfile is a ranger.container.file.File object and is a
            # reference to the currently selected file.
            target_filename = self.fm.thisfile.path

        # This is a generic function to print text in ranger.
        self.fm.notify("Let's edit the file " + target_filename + "!")

        # Using bad=True in fm.notify allows you to print error messages:
        if not os.path.exists(target_filename):
            self.fm.notify("The given file does not exist!", bad=True)
            return

        # This executes a function from ranger.core.acitons, a module with a
        # variety of subroutines that can help you construct commands.
        # Check out the source, or run "pydoc ranger.core.actions" for a list.
        self.fm.edit_file(target_filename)

    # The tab method is called when you press tab, and should return a list of
    # suggestions that the user will tab through.
    # tabnum is 1 for <TAB> and -1 for <S-TAB> by default
    def tab(self, tabnum):
        # This is a generic tab-completion function that iterates through the
        # content of the current directory.
        return self._tab_directory_content()


##############################################################################
# Added
##############################################################################


class fzf_select_tree(Command):
    """
    Modified by Jordan K.H. Wu

    :fzf_select
    Find a file using fzf.
    With a prefix argument to select only directories.

    See: https://github.com/junegunn/fzf
    """

    def execute(self):
        import subprocess
        import os
        from ranger.ext.get_executables import get_executables

        # Only show directory
        self.quantifier = True

        if 'fzf' not in get_executables():
            self.fm.notify('Could not find fzf in the PATH.', bad=True)
            return

        fd = None
        if 'fdfind' in get_executables():
            fd = 'fdfind'
        elif 'fd' in get_executables():
            fd = 'fd'

        if fd is not None:
            hidden = ('--hidden' if self.fm.settings.show_hidden else '')
            exclude = "--no-ignore-vcs --exclude={.wine,.git,.idea,.vscode,.sass-cache,node_modules,build,.local,.steam,.m2,.rangerdir,.ssh,.ghidra,.mozilla} --exclude '*.py[co]' --exclude '__pycache__'"
            fzf_default_command = '{} --follow {} {} --color=always'.format(
                fd, hidden, exclude)
        else:
            hidden = ('-false' if self.fm.settings.show_hidden else
                      r"-path '*/\.*' -prune")
            exclude = r"\( -name '\.git' -o -iname '\.*py[co]' -o -fstype 'dev' -o -fstype 'proc' \) -prune"
            fzf_default_command = 'find -L . -mindepth 1 {} -o {} -o -print | cut -b3-'.format(
                hidden, exclude)

        env = os.environ.copy()
        env['FZF_DEFAULT_COMMAND'] = fzf_default_command
        # Modified for fish shell
        env['FZF_DEFAULT_OPTS'] = "--height=100% --layout=reverse --ansi \
           --bind 'alt-k:up,alt-j:down,alt-y:preview-up,alt-e:preview-down' \
           --bind 'alt-b:preview-page-up,alt-f:preview-page-down' \
           --bind 'alt-u:preview-page-up,alt-d:preview-page-down' \
           --bind 'alt-/:change-preview-window(down|hidden|)' \
           --preview=\"tree  3 -I '.git' -I '*.py[co]' -I '__pycache__' {}\""

        fzf = self.fm.execute_command('fzf --no-multi',
                                      env=env,
                                      universal_newlines=True,
                                      stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            selected = os.path.abspath(stdout.strip())
            if os.path.isdir(selected):
                self.fm.cd(selected)
            else:
                self.fm.select_file(selected)


class fzf_select_cat(Command):
    """
    Modified by Jordan K.H. Wu

    :fzf_select
    Find a file using fzf.
    With a prefix argument to select only directories.

    See: https://github.com/junegunn/fzf
    """

    def execute(self):
        import subprocess
        import os
        from ranger.ext.get_executables import get_executables

        # Only show directory
        self.quantifier = True

        if 'fzf' not in get_executables():
            self.fm.notify('Could not find fzf in the PATH.', bad=True)
            return

        fd = None
        if 'fdfind' in get_executables():
            fd = 'fdfind'
        elif 'fd' in get_executables():
            fd = 'fd'

        if fd is not None:
            hidden = ('--hidden' if self.fm.settings.show_hidden else '')
            exclude = "--no-ignore-vcs --exclude={.wine,.git,.idea,.vscode,.sass-cache,node_modules,build,.local,.steam,.m2,.rangerdir,.ssh,.ghidra,.mozilla} --exclude '*.py[co]' --exclude '__pycache__'"
            fzf_default_command = '{} --follow {} {} --color=always'.format(
                fd, hidden, exclude)
        else:
            hidden = ('-false' if self.fm.settings.show_hidden else
                      r"-path '*/\.*' -prune")
            exclude = r"\( -name '\.git' -o -iname '\.*py[co]' -o -fstype 'dev' -o -fstype 'proc' \) -prune"
            fzf_default_command = 'find -L . -mindepth 1 {} -o {} -o -print | cut -b3-'.format(
                hidden, exclude)

        env = os.environ.copy()
        env['FZF_DEFAULT_COMMAND'] = fzf_default_command
        # Modified for fish shell
        env['FZF_DEFAULT_OPTS'] = "--height=100% --layout=reverse --ansi \
           --bind 'alt-k:up,alt-j:down,alt-y:preview-up,alt-e:preview-down' \
           --bind 'alt-b:preview-page-up,alt-f:preview-page-down' \
           --bind 'alt-u:preview-page-up,alt-d:preview-page-down' \
           --bind 'alt-/:change-preview-window(down|hidden|)' \
           --preview=\"bat -P --plain --color=always {}\""

        fzf = self.fm.execute_command('fzf --no-multi',
                                      env=env,
                                      universal_newlines=True,
                                      stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            selected = os.path.abspath(stdout.strip())
            if os.path.isdir(selected):
                self.fm.cd(selected)
            else:
                self.fm.select_file(selected)


class toggle_flat(Command):
    """
    :toggle_flat

    Flattens or unflattens the directory view.
    """

    def execute(self):
        if self.fm.thisdir.flat == 0:
            self.fm.thisdir.unload()
            if self.arg(1):
                # self.rest(1) contains self.arg(1) and everything that follows
                self.fm.thisdir.flat = int(self.rest(1))
            else:
                self.fm.thisdir.flat = -1
            self.fm.thisdir.load_content()
        else:
            self.fm.thisdir.unload()
            self.fm.thisdir.flat = 0
            self.fm.thisdir.load_content()


class cd_tmp_dir(Command):
    """
    Added by Jordan K.H. Wu

    """

    def execute(self):
        if os.path.isfile('/tmp/tmp.ranger'):
            with open('/tmp/tmp.ranger') as tmp:
                tmp_dir = tmp.readlines()[0].strip('\n')
            if os.path.isdir(tmp_dir):
                self.fm.cd(tmp_dir)
