CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    username TEXT,
    profile_picture TEXT
);

CREATE TABLE post_comments (
    post_id UUID,
    comment_id UUID,
    created_at TIMESTAMP,
    user_id UUID,
    username TEXT,
    user_profile_picture TEXT,
    content TEXT,
    total_likes BIGINT,
    total_dislikes BIGINT,
    total_replies BIGINT,
    score BIGINT,
    parent_comment_id UUID,

    PRIMARY KEY ((post_id), score, created_at, comment_id)
) WITH CLUSTERING ORDER BY (score DESC, created_at DESC, comment_id ASC);

-- Above table will store all comment related information's and is denormalized for effective retrieval of data.
-- I have added user related as well as likes dislikes and total replies to this table as it will only require a single call to DB for
-- fetching these details. I have created two new additional field likes_user_ids & dislikes_user_ids for checking if a user has already liked
-- or disliked a comment as it will store user ID's of the user interacting with it. I have also added score in DESC for effective partitioning.
-- I have added a new field parent_comment_id for distinguishing top-level comments from replies.


-- Table for tracking likes and dislikes for main comments
CREATE TABLE comment_user_interactions (
    comment_id UUID,
    user_id UUID,
    interaction_type TEXT,
    created_at TIMESTAMP,
    PRIMARY KEY ((comment_id), user_id)
);

-- Table for tracking likes and dislikes for reply comments
CREATE TABLE reply_user_interactions (
    reply_id UUID,
    user_id UUID,
    interaction_type TEXT,
    created_at TIMESTAMP,
    PRIMARY KEY ((reply_id), user_id)
);


-- Approach 1 for replies table
CREATE TABLE comment_replies (
    parent_comment_id UUID,
    reply_id UUID,
    created_at TIMESTAMP,    
    user_id UUID,
    username TEXT,
    user_profile_picture TEXT,    
    content TEXT,    
    total_likes BIGINT,
    total_dislikes BIGINT,    

    PRIMARY KEY ((post_id, parent_comment_id), created_at, reply_id)
) WITH CLUSTERING ORDER BY (created_at DESC, reply_id ASC);

-- Above table will store all replies that are there for each comment. This table is also same as comment table. Although with above approach,
-- program may need to make DB calls as the number of replies for each comment, but if pagination and batch processing is added while fetching data
-- this approach will be fine for low to medium sized replies.
-- I also added post_id as partition.

-- Approach 2 for replies table
CREATE TABLE comment_replies_by_time (
    post_id UUID,
    parent_comment_id UUID,
    reply_date DATE,
    reply_id UUID,
    created_at TIMESTAMP,
    user_id UUID,
    username TEXT,
    user_profile_picture TEXT, 
    content TEXT,
    total_likes BIGINT,
    total_dislikes BIGINT,
    PRIMARY KEY ((post_id, reply_date), parent_comment_id, created_at, reply_id)
) WITH CLUSTERING ORDER BY (parent_comment_id ASC, created_at DESC, reply_id ASC);
CREATE INDEX ON comment_replies_by_time (parent_comment_id);

-- Above alternate approach can be considered better if we have large amount of replies. In this, approach, I have created a column called reply_date
-- which I am also using for partitioning. This will create partitions based on time intervals. We also can decide what time interval we can give 
-- for reply date, if the data is too frequent, even hours can be given for partitions but it may create lot of partitions if the data is less.
-- While inserting the data, the current date with early time should be taken for this field. 


CREATE TABLE total_comments (
    post_id UUID,
    total_comments BIGINT,
    PRIMARY KEY (post_id)
);

-- Above table will store total comments count.


-- Views
CREATE MATERIALIZED VIEW comments_by_top_rated AS
    SELECT * FROM post_comments
    WHERE post_id IS NOT NULL 
    AND score IS NOT NULL 
    AND created_at IS NOT NULL 
    AND comment_id IS NOT NULL
    PRIMARY KEY ((post_id), score, created_at, comment_id)
    WITH CLUSTERING ORDER BY (score DESC, created_at DESC, comment_id ASC);

-- I have created above view so that when user sorts it based on top rated comments, it wont load the actual table for parallel write operation.