-- 1. User Table
CREATE TABLE users (
    user_id UUID,
    username TEXT,
    profile_picture TEXT,
    PRIMARY KEY (user_id)
);

-- Above table will store User information which will allow associating comments, likes or replies with corresponding user.
-- Primary key as user_id will ensure uniqueness for each user and is designed for quick lookup of user details.
---------------------------------------------------------------------------------------------------------------------------

-- 2. Comment Table
CREATE TABLE post_comments_by_time (
    post_id UUID,
    created_at TIMESTAMP,
    comment_id UUID,
    user_id UUID,
    username TEXT,
    profile_picture TEXT,
    content TEXT,
    PRIMARY KEY ((post_id), created_at, comment_id)
) WITH CLUSTERING ORDER BY (created_at DESC, comment_id ASC);

-- Above table will store comments for each post, sorted by creation time which will store the newest first.
-- Partition on post_id will group comments by post and clustering of created_at and comment_id will sort comments by recent,
-- ensuring efficient retrieval.
---------------------------------------------------------------------------------------------------------------------------

-- 3. Likes Count Table
CREATE TABLE comment_likes_counter (
    comment_id UUID,
    likes_count counter,
    PRIMARY KEY (comment_id)
);

-- Above table will track all the likes on a comment using a counter column. Counter is used here because its efficient for
-- operations like incrementing a count
---------------------------------------------------------------------------------------------------------------------------

-- 4. Dislikes Count Table
CREATE TABLE comment_dislikes_counter (
    comment_id UUID,
    dislikes_count counter,
    PRIMARY KEY (comment_id)
);

-- Above table will track all the dislikes on a comment using counter column.
---------------------------------------------------------------------------------------------------------------------------

-- 5. Replies Count Table
CREATE TABLE comment_replies_counter (
    comment_id UUID,
    replies_count counter,
    PRIMARY KEY (comment_id)
);

-- Above table will track all the replies on a comment using counter column.
---------------------------------------------------------------------------------------------------------------------------

-- 6. Replies Table
CREATE TABLE comment_replies (
    comment_id UUID,
    created_at TIMESTAMP,
    reply_id UUID,
    user_id UUID,
    username TEXT,
    profile_picture TEXT,
    content TEXT,
    PRIMARY KEY ((comment_id), created_at, reply_id)
) WITH CLUSTERING ORDER BY (created_at DESC, reply_id ASC);

-- Above table will store replies to a comment ordered by creation time. Partition on comment_id ensures quick retrieval of
-- replies for a specific comment. Clustering by created_at DESC order replies in reverse order.
---------------------------------------------------------------------------------------------------------------------------

-- 7. Materialized View for Comments Count by Post
CREATE MATERIALIZED VIEW post_comments_count AS
    SELECT post_id, created_at, comment_id
    FROM post_comments_by_time
    WHERE post_id IS NOT NULL AND created_at IS NOT NULL AND comment_id IS NOT NULL
    PRIMARY KEY (post_id, created_at, comment_id)
    WITH CLUSTERING ORDER BY (created_at DESC, comment_id ASC);

-- Above view is created to efficiently count the number of comments for each post. This will allow to query how many a
-- comments a particular post has without scanning the entire comments table.
---------------------------------------------------------------------------------------------------------------------------


-- 8. Comments Score Table
CREATE TABLE post_comments_by_score (
    post_id UUID,
    score bigint,
    created_at TIMESTAMP,
    comment_id UUID,
    user_id UUID,
    username TEXT,
    profile_picture TEXT,
    content TEXT,
    PRIMARY KEY ((post_id), score, created_at, comment_id)
) WITH CLUSTERING ORDER BY (score DESC, created_at DESC, comment_id ASC);

-- Above table will enable ranking of comments by a score, that is, likes - dislikes.
-- Clustering by score DESC ensures the highest scoring comments are prioritized and partitioning by post_id will help in 
-- efficient retrieval of replies.
-- Algorithm for fetching top rated comments:
-- score = likes_count - disliked_count + log(reply_count + 1) order by created_at DESC
---------------------------------------------------------------------------------------------------------------------------

-- 9. Likes Tracking Table
CREATE TABLE comment_likes_by_user (
    comment_id UUID,
    user_id UUID,
    created_at TIMESTAMP,
    PRIMARY KEY ((comment_id), user_id)
);

-- Above table will track which users liked a comment. This will prevent duplicate likes by the same user.
---------------------------------------------------------------------------------------------------------------------------

-- 10. Dislikes Tracking Table
CREATE TABLE comment_dislikes_by_user (
    comment_id UUID,
    user_id UUID,
    created_at TIMESTAMP,
    PRIMARY KEY ((comment_id), user_id)
);

-- Above table will track which users disliked a comment. This will prevent duplicate dislikes by the same user.
---------------------------------------------------------------------------------------------------------------------------


-- The above schema will have extreme fast reads as all the necessary data for displaying comments is readily available in a 
-- single row for each comment. This minimizes the need for joins which will lower the latency needs. Separate tables for time-based
-- and score based sorting eliminate the need for expensive sorting operations at query time and also the materialized view provides 
-- very fast access to the total comment count. 
-- As the above schema is heavily denormalized, it will prioritize read performance at the cost of write performance and storage space.