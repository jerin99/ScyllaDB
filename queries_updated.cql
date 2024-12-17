-- 1. For total comments
SELECT total_comments 
FROM total_comments 
WHERE post_id = ?;


-- 2. For retrieving comments by pagination (200 each)
SELECT
    comment_id, 
    created_at, 
    user_id, 
    username, 
    user_profile_picture, 
    content, 
    total_likes, 
    total_dislikes, 
    total_replies, 
    score
FROM post_comments
WHERE post_id = ?
LIMIT 200;

-- With pagination, above query will fetch all details related to a post's comments in a single call.

-- 3. For fetching replies for above fetched comments
-- First Approach
BEGIN BATCH

    SELECT reply_id, created_at, user_id, username, user_profile_picture, 
           content, total_likes, total_dislikes
    FROM comment_replies 
    WHERE parent_comment_id = ?
    LIMIT 50 PER PARTITION;

    SELECT reply_id, created_at, user_id, username, user_profile_picture, 
           content, total_likes, total_dislikes
    FROM comment_replies 
    WHERE parent_comment_id = ?
    LIMIT 50 PER PARTITION;

    SELECT reply_id, created_at, user_id, username, user_profile_picture, 
           content, total_likes, total_dislikes
    FROM comment_replies 
    WHERE parent_comment_id = ?
    LIMIT 50 PER PARTITION;

APPLY BATCH;

-- A dynamic batch query needs to be implemented from server side language

-- ****************OR*****************
--  Second Approach

SELECT reply_id, created_at, user_id, username, user_profile_picture, 
           content, total_likes, total_dislikes
FROM comment_replies 
WHERE parent_comment_id IN (?, ?, ?, ?, ?)
LIMIT 50 PER PARTITION;

-- Above approach will be feasible if the data is limited.
-- If there are huge volume of data for replies, we can also add additional partition on created day and can filter the replies based on the dates.

-- **************OR************
--  Third Approach

SELECT * FROM comment_replies_by_time
WHERE post_id = ?
AND reply_date = ?
AND comment_id = ?

OR 

SELECT * FROM comment_replies_by_time
WHERE post_id = ?
AND reply_date >= ? AND reply_date <= ?
AND comment_id = ?



-- 4. Insert a new comment
BEGIN BATCH
    INSERT INTO post_comments (
        post_id, comment_id, created_at, user_id, username, user_profile_picture, 
        content, total_likes, total_dislikes, total_replies, score, 
        likes_user_ids, dislikes_user_ids
    ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, [], []);
    
    UPDATE total_comments
    SET total_comments = total_comments + 1
    WHERE post_id = ?;
APPLY BATCH;

-- Above statement will insert a comment and also update the total comment in a single batch.


-- 5. Insert a reply
BEGIN BATCH
    INSERT INTO comment_replies (
        parent_comment_id, reply_id, created_at, user_id, username, user_profile_picture, 
        content, total_likes, total_dislikes, likes_user_ids, dislikes_user_ids
    ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, [], []);

    UPDATE post_comments
    SET total_replies = total_replies + 1
    WHERE post_id = ? AND comment_id = ?;

    UPDATE total_comments
    SET total_comments = total_comments + 1
    WHERE post_id = ?;
APPLY BATCH;

-- Above statement will insert a reply for a specific comment and also update the total comments and total replies in a single batch.


-- 6. Insert a like or a dislike
BEGIN BATCH
    UPDATE post_comments
    SET 
        total_likes = total_likes + 1,
        likes_user_ids = likes_user_ids + [?], 
        score = ((total_likes * 10) - (total_dislikes * 5)) + (total_replies * 2) - (dateDiffInHours(created_at, now()) / 24)
    WHERE post_id = ? AND comment_id = ?
    IF NOT ? IN likes_user_ids AND NOT ? IN dislikes_user_ids;

    UPDATE total_comments
    SET total_comments = total_comments
    WHERE post_id = ?;

-- Above code will update liked, dislikes and also score for a specific comment based on the interaction.
-- Updated algorithm for score to point based approach
-- SET score = 
--     ((total_likes * 10) - (total_dislikes * 5)) + (total_replies * 2) - (created_time_hour - current_hour)/24
-- It will also check if a user has already liked or disliked a comment and will only allow if not.

-- If we are using second approach for fetching replies, then total DB calls will be 3
-- 1. For total comments
-- 2. For comments
-- 3. For replies