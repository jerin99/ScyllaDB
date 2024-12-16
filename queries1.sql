-- 1. Inserting a new comment
INSERT INTO post_comments_by_time (post_id, created_at, comment_id, user_id, username, profile_picture, content)
VALUES (uuid(), toTimestamp(now()), uuid(), uuid(), 'john', 'profile_pic_john')


-- 2. Selecting a new comment
SELECT * from post_comments_by_time where post_id = ?;


-- 3. Updating the likes on a count
UPDATE comment_likes_counter SET likes_count = likes_count+1 WHERE comment_id = ?;


-- 4. Selecting the likes count
SELECT likes_count FROM comment_likes_counter WHERE comment_id = ?;


-- 5. Updating the dislikes on a count
UPDATE comment_dislikes_counter SET dislikes_count = dislikes_count+1 WHERE comment_id = ?;


-- 6. Selecting the dislikes count
SELECT dislikes_count FROM comment_dislikes_counter WHERE comment_id = ?;


-- 7. Update the count of replies on a comment
UPDATE comment_replies_counter SET replies_count = replies_count+1 WHERE comment_id = ?;


-- 8. Select the count of replies on a comment
SELECT replies_count FROM comment_replies_counter WHERE comment_id = ?;


-- 9. Insert a reply for a comment
INSERT INTO comment_replies (comment_id, created_at, reply_id, user_id, username, profile_picture, content)
VALUES (uuid(), toTimestamp(now()), uuid(), uuid(), 'jane', 'profile_pic_jane');


-- 10. Select the replies for a comment
SELECT * FROM comment_replies WHERE comment_id = ?;


-- 11. Inserting data for fetching top comments.
INSERT INTO post_comments_by_score (post_id, score, created_at, comment_id, user_id, username, profile_picture, content)
VALUES(uuid(), 10, toTimestamp(now()), uuid(), uuid(), 'john', 'profile_pic_john');


-- 12. Selecting top rated comments
SELECT * FROM post_comments_by_score WHERE post_id = ?;


-- 13. Inserting data for duplicate like check
INSERT INTO comment_likes_by_user (comment_id, user_id, created_at)
VALUES (uuid(), uuid(), toTimestamp(now()));


-- 14. For checking if a user has already liked for a post
SELECT * FROM comment_likes_by_user WHERE comment_id = ?;


-- 15. Inserting data for duplicate dislike check
INSERT INTO comment_dislikes_by_user (comment_id, user_id, created_at)
VALUES (uuid(), uuid(), toTimestamp(now()));


-- 16. For checking if a user has already disliked for a post
SELECT * FROM comment_dislikes_by_user WHERE comment_id = ?;