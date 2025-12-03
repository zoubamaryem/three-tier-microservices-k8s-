-- ==========================================
-- TABLE 1 : USERS (pour Microservice 1)
-- ==========================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created ON users(created_at);

-- Données de test users
INSERT INTO users (name, email) VALUES
    ('Alice Dupont', 'alice@example.com'),
    ('Bob Martin', 'bob@example.com'),
    ('Charlie Bernard', 'charlie@example.com'),
    ('David Petit', 'david@example.com')
ON CONFLICT (email) DO NOTHING;

-- ==========================================
-- TABLE 2 : POSTS (pour Microservice 2)
-- ==========================================
CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at);

-- Données de test posts
INSERT INTO posts (user_id, title, content) VALUES
    (1, 'Mon premier post', 'Ceci est le contenu de mon premier post sur cette plateforme!'),
    (1, 'Kubernetes est génial', 'J''apprends Kubernetes et c''est vraiment puissant.'),
    (2, 'Microservices architecture', 'Les microservices permettent une meilleure scalabilité.'),
    (3, 'Docker et containers', 'Docker simplifie le déploiement des applications.')
ON CONFLICT DO NOTHING;

-- ==========================================
-- VUES POUR STATISTIQUES
-- ==========================================
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    COUNT(*) as total_users,
    MAX(created_at) as last_user_created,
    MIN(created_at) as first_user_created
FROM users;

CREATE OR REPLACE VIEW post_stats AS
SELECT 
    COUNT(*) as total_posts,
    COUNT(DISTINCT user_id) as users_with_posts,
    MAX(created_at) as last_post_created
FROM posts;

CREATE OR REPLACE VIEW posts_per_user AS
SELECT 
    u.id as user_id,
    u.name as user_name,
    COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
GROUP BY u.id, u.name
ORDER BY post_count DESC;
