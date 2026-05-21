# zdansible


## Commands Needed

- `(crontab -l 2>/dev/null; echo "0 */8 * * * echo \"ssh \$(sudo systemctl restart ssh) restarted => \$(date)\" >> ~/ssh-restart.log") | crontab -`
