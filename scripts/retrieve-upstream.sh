#!/usr/bin/env bash
set -euo pipefail

# Define color codes for terminal output
COLOR_GREEN="\e[32m"
COLOR_RED="\e[31m"
COLOR_YELLOW="\e[33m"
COLOR_BRIGHTYELLOW="\e[93m"
COLOR_RESET="\e[0m"

print_colored() {
    local color=$1
    local message=$2
    printf "${color}${message}${COLOR_RESET}\n"
}

remote_name="${REMOTE:-upstream}"
remote_branch="${REMOTE_BRANCH:-}"
upstream_url="${UPSTREAM_URL:-https://github.com/JackYoung27/MDviewer.git}"

usage() {
    printf '%b\n' "${COLOR_YELLOW}Usage: retrieve-upstream.sh [options]${COLOR_RESET}"
    printf '\n'
    printf '%s\n' 'Configure upstream remote (if needed) and rebase the current branch onto it.'
    printf '%s\n' 'If conflicts occur, resolve them manually and run: git rebase --continue'
    printf '\n'
    printf '%b\n' "${COLOR_YELLOW}Options:${COLOR_RESET}"
    printf '%s\n' '  -h, --help             Show this help text.'
    printf '%s\n' '  -r, --remote NAME      Remote name. Defaults to REMOTE or upstream.'
    printf '%s\n' '  -u, --url URL          Upstream repository URL.'
    printf '%s\n' '  -b, --branch NAME      Remote branch to rebase onto. Defaults to REMOTE_BRANCH or remote HEAD.'
}

die() {
    print_colored "$COLOR_RED" "error: $*" >&2
    exit 1
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -r|--remote)
                [[ $# -ge 2 ]] || die "missing value for $1"
                remote_name="$2"
                shift 2
                ;;
            -u|--url)
                [[ $# -ge 2 ]] || die "missing value for $1"
                upstream_url="$2"
                shift 2
                ;;
            -b|--branch)
                [[ $# -ge 2 ]] || die "missing value for $1"
                remote_branch="$2"
                shift 2
                ;;
            *)
                die "unknown option: $1"
                ;;
        esac
    done
}

ensure_upstream_remote() {
    if git remote get-url "$remote_name" >/dev/null 2>&1; then
        local existing_url
        existing_url=$(git remote get-url "$remote_name")
        if [[ "$existing_url" != "$upstream_url" ]]; then
            print_colored "$COLOR_BRIGHTYELLOW" "Updating remote '$remote_name' to: $upstream_url"
            git remote set-url "$remote_name" "$upstream_url"
        fi
    else
        print_colored "$COLOR_BRIGHTYELLOW" "Adding remote '$remote_name': $upstream_url"
        git remote add "$remote_name" "$upstream_url"
    fi
}

validate_git_context() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "must be run inside a Git work tree"

    if [[ -n "$(git status --porcelain)" ]]; then
        die "working tree is not clean; commit or stash local changes before rebasing"
    fi
}

resolve_remote_branch() {
    local remote_head

    if [[ -z "$remote_branch" ]]; then
        remote_head="$(git symbolic-ref --quiet --short "refs/remotes/$remote_name/HEAD" 2>/dev/null || true)"
        if [[ -n "$remote_head" ]]; then
            remote_branch="${remote_head#"$remote_name/"}"
        else
            remote_branch="$(git remote show "$remote_name" | awk -F': ' '/HEAD branch/ {print $2}')"
        fi
    fi

    [[ -n "$remote_branch" ]] || die "could not determine default branch for '$remote_name'"
    git rev-parse --verify --quiet "$remote_name/$remote_branch" >/dev/null || die "remote branch '$remote_name/$remote_branch' was not found"
}

main() {
    local current_branch

    parse_arguments "$@"
    validate_git_context
    ensure_upstream_remote

    print_colored "$COLOR_BRIGHTYELLOW" "Fetching upstream commits..."
    git fetch "$remote_name" --prune --tags

    resolve_remote_branch

    current_branch="$(git branch --show-current)"
    [[ -n "$current_branch" ]] || die "currently in detached HEAD; switch to a branch before rebasing"

    print_colored "$COLOR_BRIGHTYELLOW" "Rebasing $current_branch onto $remote_name/$remote_branch..."
    git rebase "$remote_name/$remote_branch"
    print_colored "$COLOR_GREEN" "Rebase completed successfully!"
    print_colored "$COLOR_YELLOW" "The upstream remote '$remote_name' has been left in place for future updates."
}

main "$@"
