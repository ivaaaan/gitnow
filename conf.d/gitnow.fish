# GitNow — Speed up your Git workflow. 🐠
# https://github.com/joseluisq/gitnow
# 
# NOTE:
#   Fish 2.2.0 doesn't include native snippet support.
#   Upgrade to Fish >= 2.3.0 or append the following code to your ~/.config/fish/config.fish

set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
set -q fish_config; or set -g fish_config $XDG_CONFIG_HOME/fish
set -q gitnow_path; or set -g gitnow_path $fish_config

source "$gitnow_path/functions/__gitnow_functions.fish"
source "$gitnow_path/functions/__gitnow_manual.fish"

function gitnow -d "Gitnow: Speed up your Git workflow. 🐠"
  __gitnow_manual | less -r

  commandline -f repaint;
end

function state -d "Gitnow: Show the working tree status in compact way"
  echo "Current working tree status:"
  command git status -sb
  commandline -f repaint;
end

function stage -d "Gitnow: Stage files in current working directory"
  set -l len (count $argv)
  set -l opts .

  if test $len -gt 0
    set opts $argv
  end

  command git add $opts
  commandline -f repaint;
end

function unstage -d "Gitnow: Unstage files in current working directory"
  set -l len (count $argv)
  set -l opts .

  if test $len -gt 0
    set opts $argv
  end

  command git reset $opts
  commandline -f repaint;
end

function commit -d "Gitnow: Commit changes to the repository"
  set -l len (count $argv)

  if test $len -gt 0
    command git commit $argv
  else
    command git commit
  end

  commandline -f repaint;
end

function commit-all -d "Gitnow: Add and commit all changes to the repository"
  stage
  commit .
end

function pull -d "Gitnow: Pull changes from remote server but saving uncommitted changes"
  set -l len (count $argv)
  set -l xorigin (__gitnow_current_remote)
  set -l xbranch (__gitnow_current_branch_name)
  set -l xcmd ""
  
  echo "⚡️ Pulling changes..."

  set -l xdefaults --rebase --autostash

  if test $len -gt 2 
    set xcmd $argv

    echo "Mode: Manual"
    echo "Default flags: $xdefaults"
    echo
  else
    echo "Mode: Auto"
    echo "Default flags: $xdefaults"

    if test $len -eq 1
      set xbranch $argv[1]
    end

    if test $len -eq 2
      set xorigin $argv[1]
      set xbranch $argv[2]
    end

    set xcmd $xorigin $xbranch
    set -l xremote_url (command git config --get "remote.$xorigin.url")

    echo "Remote URL: $xorigin ($xremote_url)"
    echo "Remote branch: $xbranch"
    echo
  end

  command git pull $xcmd $xdefaults
  commandline -f repaint;
end

# Git push with --set-upstream
# Shortcut inspired from https://github.com/jamiew/git-friendly
function push -d "Gitnow: Push commit changes to remote repository"
  set -l opts $argv
  set -l xorigin (__gitnow_current_remote)
  set -l xbranch (__gitnow_current_branch_name)

  echo "🚀 Pushing changes..."

  if test (count $opts) -eq 0
    set opts $xorigin $xbranch
    set -l xremote_url (command git config --get "remote.$xorigin.url")

    echo "Mode: Auto"
    echo "Remote URL: $xorigin ($xremote_url)"
    echo "Remote branch: $xbranch"
  else
    echo "Mode: Manual"
  end

  echo

  command git push --set-upstream $opts
  commandline -f repaint;
end

function upstream -d "Gitnow: Commit all changes and push them to remote server"
  commit-all
  push
end

function feature -d "GitNow: Creates a new feature (Gitflow) branch from current branch"
  set -l xprefix "feature"
  set -l xbranch (__gitnow_slugify $argv[1])
  set -l xbranch_full "$xprefix/$xbranch"
  set -l xfound (__gitnow_check_if_branch_exist $xbranch_full)

  if test $xfound -eq 1
    echo "Branch `$xbranch_full` already exists. Nothing to do."
  else
    command git stash
    __gitnow_new_branch_switch "$xbranch_full"
    command git stash pop
  end

  commandline -f repaint;
end

function hotfix -d "GitNow: Creates a new hotfix (Gitflow) branch from current branch"
  set -l xprefix "hotfix"
  set -l xbranch (__gitnow_slugify $argv[1])
  set -l xbranch_full "$xprefix/$xbranch"
  set -l xfound (__gitnow_check_if_branch_exist $xbranch_full)

  if test $xfound -eq 1
    echo "Branch `$xbranch_full` already exists. Nothing to do."
  else
    command git stash
    __gitnow_new_branch_switch "$xbranch_full"
    command git stash pop
  end

  commandline -f repaint;
end

function move -d "GitNow: Switch from current branch to another but stashing uncommitted changes"
  if test (count $argv) -gt 0
    set -l xbranch $argv[1]
    set -l xfound (__gitnow_check_if_branch_exist $xbranch)

    if test $xfound -eq 1
      if [ "$xbranch" = (__gitnow_current_branch_name) ]
        echo "Branch `$xbranch` is the same like current branch. Nothing to do."
      else
        command git stash
        command git checkout $xbranch
        command git stash pop
      end
    else
      echo "Branch `$xbranch` was not found. No possible to switch."
    end
  else
    echo "Provide a branch name to move."
  end

  commandline -f repaint;
end

function logs -d "Gitnow: Shows logs in a fancy way"
  set -l args HEAD

  if test -n "$argv"
    set args $argv
  end

  command git log $args --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit | command less -r

  commandline -f repaint;
end

function github -d "Gitnow: Clone a GitHub repository using SSH"
  set -l repo (__gitnow_clone_params $argv)
  __gitnow_clone_repo $repo "github"

  commandline -f repaint;
end

function bitbucket -d "Gitnow: Clone a Bitbucket Cloud repository using SSH"
  set -l repo (__gitnow_clone_params $argv)
  __gitnow_clone_repo $repo "bitbucket"

  commandline -f repaint;
end
