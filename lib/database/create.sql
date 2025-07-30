PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users(
    user_id       INTEGER PRIMARY KEY,
    password_hash TEXT    NOT NULL,
    salt          BLOB    NOT NULL DEFAULT (randomblob(32)),

    username TEXT NOT NULL UNIQUE CHECK (
        length(username) >= 3 AND
        length(username) <= 128
    ),
    profile_picture_id INTEGER,
    bio TEXT CHECK (
        length(bio) <= 1024
    ),
    status_id INTEGER DEFAULT 0 CHECK (
        status_id >=0 AND
        status_id <=255
    ),

    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
    updated_at INTEGER NOT NULL DEFAULT (unixepoch()),

    FOREIGN KEY(profile_picture_id) REFERENCES media(media_id)
) STRICT;

CREATE TABLE IF NOT EXISTS channels(
    channel_id INTEGER PRIMARY KEY ,

    channel_name TEXT NOT NULL CHECK (
        length(channel_name) > 0 AND
        length(channel_name) < 256
    ),
    icon_id INTEGER,

    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
    updated_at INTEGER NOT NULL DEFAULT (unixepoch()),

    FOREIGN KEY(icon_id) REFERENCES media(media_id)
) STRICT;

CREATE TABLE IF NOT EXISTS messages(
    message_id INTEGER PRIMARY KEY,
    sent_at    INTEGER NOT NULL DEFAULT (unixepoch()),
    user_id    INTEGER NOT NULL,
    channel_id INTEGER NOT NULL,
    reply_to   INTEGER,

    content TEXT NOT NULL CHECK (
        length(content) > 0 AND
        length(content) < 4096
    ),

    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
    updated_at INTEGER NOT NULL DEFAULT (unixepoch()),

    FOREIGN KEY(user_id)    REFERENCES users(user_id)
    FOREIGN KEY(channel_id) REFERENCES channels(channel_id)
    FOREIGN KEY(reply_to)   REFERENCES messages(message_id)
) STRICT;

CREATE TABLE IF NOT EXISTS message_media (
    message_id INTEGER NOT NULL,
    media_id INTEGER NOT NULL,
    PRIMARY KEY (message_id, media_id),
    FOREIGN KEY(message_id) REFERENCES messages(message_id),
    FOREIGN KEY(media_id) REFERENCES media(media_id)
) STRICT;

CREATE TABLE IF NOT EXISTS media (
    media_id INTEGER PRIMARY KEY,
    media_type_id INTEGER NOT NULL,

    filename TEXT CHECK (
        length(filename) > 0 AND
        length(filename) < 1024
    ),
    content BLOB NOT NULL CHECK (
        length(content) > 0 AND
        length(content) <= (50 * 1024 * 1024) -- 50 MiB
    ),
    hash BLOB UNIQUE,

    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
    updated_at INTEGER NOT NULL DEFAULT (unixepoch()),

    FOREIGN KEY(media_type_id) REFERENCES media_type(media_type_id)
) STRICT;

CREATE TABLE IF NOT EXISTS media_type (
    media_type_id INTEGER PRIMARY KEY,
    media_type_name TEXT NOT NULL UNIQUE CHECK (
        length(media_type_name) > 0 AND
        length(media_type_name) < 128
    ),
    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
    updated_at INTEGER NOT NULL DEFAULT (unixepoch())
) STRICT;


/* TRIGGERS */
/* To show triggers: 
    SELECT * FROM sqlite_master WHERE type = 'trigger'; */

/* update_at triggers */

CREATE TRIGGER trig_users_update
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    UPDATE users SET updated_at = (unixepoch()) WHERE user_id = NEW.user_id;
END;

CREATE TRIGGER trig_channels_update
AFTER UPDATE ON channels FOR EACH ROW
BEGIN
    UPDATE channels SET updated_at = (unixepoch()) WHERE channel_id = NEW.channel_id;
END;

CREATE TRIGGER trig_messages_update
AFTER UPDATE ON messages
FOR EACH ROW
BEGIN
    UPDATE messages SET updated_at = (unixepoch()) WHERE message_id = NEW.message_id;
END;

CREATE TRIGGER trig_media_update
AFTER UPDATE ON media
FOR EACH ROW
BEGIN
    UPDATE media SET updated_at = (unixepoch()) WHERE media_id = NEW.media_id;
END;

CREATE TRIGGER trig_media_type_update
AFTER UPDATE ON media_type
FOR EACH ROW
BEGIN
    UPDATE media_type SET updated_at = (unixepoch()) WHERE media_type_id = NEW.media_type_id;
END;


/* media hash trigger */

-- CREATE TRIGGER trig_media_hash
-- AFTER INSERT ON media
-- FOR EACH ROW
-- WHEN (NEW.hash IS NULL)
-- BEGIN
--    UPDATE media SET hash = sha3(IFNULL(filename,'')||content) WHERE media_id = NEW.media_id;
-- END;


/* check profile picture media_type is 'image' */

CREATE TRIGGER trig_insert_check_image_profile_picture
BEFORE INSERT ON users
FOR EACH ROW
WHEN (NEW.profile_picture_id IS NOT NULL)
BEGIN
    SELECT CASE
        WHEN (SELECT media_type_name FROM media_type WHERE media_type_id = (SELECT media_type_id FROM media WHERE media_id = NEW.profile_picture_id)) != 'image'
        THEN RAISE(ABORT, 'Profile picture must be an ''image'' type')
    END;
END;

CREATE TRIGGER trig_update_check_image_profile_picture
BEFORE UPDATE ON users
FOR EACH ROW
WHEN (NEW.profile_picture_id IS NOT NULL)
BEGIN
    SELECT CASE
        WHEN (SELECT media_type_name FROM media_type WHERE media_type_id = (SELECT media_type_id FROM media WHERE media_id = NEW.profile_picture_id)) != 'image'
        THEN RAISE(ABORT, 'Profile picture must be an ''image'' type')
    END;
END;

CREATE TRIGGER trig_insert_check_image_channel_icon
BEFORE INSERT ON channels
FOR EACH ROW
WHEN (NEW.icon_id IS NOT NULL)
BEGIN
    SELECT CASE
        WHEN (SELECT media_type_name FROM media_type WHERE media_type_id = (SELECT media_type_id FROM media WHERE media_id = NEW.icon_id)) != 'image'
        THEN RAISE(ABORT, 'Channel icon must be an ''image'' type')
    END;
END;

CREATE TRIGGER trig_update_check_image_channel_icon
BEFORE UPDATE ON channels
FOR EACH ROW
WHEN (NEW.icon_id IS NOT NULL)
BEGIN
    SELECT CASE
        WHEN (SELECT media_type_name FROM media_type WHERE media_type_id = (SELECT media_type_id FROM media WHERE media_id = NEW.icon_id)) != 'image'
        THEN RAISE(ABORT, 'Channel icon must be an ''image'' type')
    END;
END;

CREATE TRIGGER trig_insert_message_media
BEFORE INSERT ON message_media
FOR EACH ROW
WHEN (NEW.message_id IS NOT NULL)
BEGIN
    SELECT CASE
        WHEN (SELECT COUNT(message_id) FROM message_media WHERE message_id = NEW.message_id) >= 255
        THEN RAISE(ABORT, 'Message can''t have more than 255 attached media')
    END;
END;

