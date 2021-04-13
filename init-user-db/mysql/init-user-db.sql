CREATE USER 'mattermost'@'%' IDENTIFIED BY 'mattermost';
CREATE DATABASE mattermost;
GRANT ALL PRIVILEGES ON mattermost.* TO 'mattermost'@'%';