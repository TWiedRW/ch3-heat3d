#!/usr/bin/Rscript
# Sorry this isn't elegant but necessary for the cron tab to work
setwd("~/Projects/Students/Wiederich-Tyler/ch3-heat3d/")

# Set up authentication via ssh
cred <- git2r::cred_ssh_key("~/.ssh/id_rsa.pub", "~/.ssh/id_rsa")
repo <- git2r::repository()
git2r::config(repo = repo, global = F, "Susan-auto", "srvanderplas@gmail.com")

# Log job start
httr::POST("https://hc-ping.com/6cd59829-4f55-4662-80a8-370119b57a99/start")

# Check repo status
status <- git2r::status()

tmp <- status$unstaged
modified <- names(tmp) == "modified"
modified <- unlist(tmp[modified])

# If db has been modified
if (any(stringr::str_detect(modified, "(shiny-apps/experiment-heat3d/.*\\.db)"))) {
  
  # Copy database/codes to one drive
  file.copy(modified, file.path("/btrstorage", "OneDrive", "Data", "2025-3d-heatmaps"), overwrite = T)

  # Add changed db to commit and commit
  git2r::add(repo = '.', "shiny-apps/experiment-heat3d/*.db")
  try(git2r::commit(message = "Update data and codes"))

  # Update
  git2r::pull(repo = ".", credentials = cred)
  git2r::push(getwd(), credentials = cred)

  if (length(git2r::status()$unstaged$conflicted) > 0) {
    # Log merge conflict, signal failure (Susan gets an email)
    httr::POST("https://hc-ping.com/6cd59829-4f55-4662-80a8-370119b57a99/fail", body = "Merge conflict")
  } else {
    # Log success
    httr::POST("https://hc-ping.com/6cd59829-4f55-4662-80a8-370119b57a99", body = "Changes pushed")
  }
} else {
  # Log no changes
  httr::POST("https://hc-ping.com/6cd59829-4f55-4662-80a8-370119b57a99", body = "No changes")
}

git2r::config(repo = repo, global = F, "Susan Vanderplas", "srvanderplas@gmail.com")
