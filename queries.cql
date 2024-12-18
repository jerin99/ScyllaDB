-- 1. For total comments
SELECT total_comments 
FROM total_comments 
WHERE post_id = ?;


-- 2. For retrieving comments by pagination (200 each)
SELECT
    comment_id, 
    created_at, 
    user_id, 
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
SELECT 
    reply_id, 
    created_at, 
    user_id,
    user_profile_picture,
    content, 
    total_likes, 
    total_dislikes
FROM comment_replies 
WHERE post_id = ? AND parent_comment_id = ?
LIMIT 50;

-- 4. Check user interaction
SELECT interaction_type
FROM comment_user_interactions
WHERE comment_id = ? AND user_id IN (?, ?, ?, ?);

-- Check for likes dislikes
SELECT comment_id, interaction_type, user_id
FROM comment_user_interactions
WHERE comment_id IN (?, ?, ?, ?);

-- 4. Insert a new comment
BEGIN BATCH
    INSERT INTO post_comments (
        post_id, comment_id, created_at, user_id, username, user_profile_picture, 
        content, total_likes, total_dislikes, total_replies, score, parent_comment_id
    ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, ?);
    
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
    INSERT INTO comment_user_interactions(
        comment_id,
        user_id,
        interaction_type,
        created_at
    ) VALUES(?, ?, ?, toTimeStamp(now())) IF NOT EXISTS;

    UPDATE post_comments
    SET
        total_likes = total_likes+1
        score = ((total_likes * 10) - (total_dislikes * 5)) + (total_replies * 2) - (dateDiffInHours(created_at, now()) / 24)
        -- I think above score calculation will be better to do in backend language as it will increase computation for db.
    WHERE post_id = ? AND comment_id = ?;
    
APPLY BATCH;

-- Above code will update liked, dislikes and also score for a specific comment based on the interaction.
-- Updated algorithm for score to point based approach
-- SET score = 
--     ((total_likes * 10) - (total_dislikes * 5)) + (total_replies * 2) - (created_time_hour - current_hour)/24
-- It will also check if a user has already liked or disliked a comment and will only allow if not.