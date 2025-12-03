from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import logging
import requests
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'postgres-service'),
    'port': os.environ.get('DB_PORT', '5432'),
    'database': os.environ.get('DB_NAME', 'microservices_db'),
    'user': os.environ.get('DB_USER', 'appuser'),
    'password': os.environ.get('DB_PASSWORD', 'password')
}

# URL du Users Service (COMMUNICATION INTER-MICROSERVICES)
USERS_SERVICE_URL = os.environ.get('USERS_SERVICE_URL', 'http://users-service:5001')

def get_db():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logger.error(f"DB Error: {e}")
        return None

def verify_user_exists(user_id):
    """Vérifie qu'un utilisateur existe via le Users Service"""
    try:
        logger.info(f"🔗 Communication avec Users Service pour vérifier user {user_id}")
        response = requests.get(f"{USERS_SERVICE_URL}/users/{user_id}", timeout=5)
        
        if response.status_code == 200:
            logger.info(f"✅ User {user_id} existe")
            return True, response.json().get('user')
        elif response.status_code == 404:
            logger.warning(f"⚠️ User {user_id} n'existe pas")
            return False, None
        else:
            logger.error(f"❌ Erreur Users Service: {response.status_code}")
            return False, None
    except requests.Timeout:
        logger.error("❌ Timeout vers Users Service")
        return False, None
    except Exception as e:
        logger.error(f"❌ Erreur communication: {e}")
        return False, None

# ==================== HEALTH ====================

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'posts-service'}), 200

@app.route('/ready', methods=['GET'])
def ready():
    # Vérifier DB
    conn = get_db()
    if not conn:
        return jsonify({'status': 'not ready', 'database': 'disconnected'}), 503
    
    try:
        cur = conn.cursor()
        cur.execute('SELECT 1')
        cur.close()
        conn.close()
        
        # Vérifier Users Service
        try:
            response = requests.get(f"{USERS_SERVICE_URL}/health", timeout=3)
            users_service_ok = response.status_code == 200
        except:
            users_service_ok = False
        
        if users_service_ok:
            return jsonify({
                'status': 'ready',
                'database': 'connected',
                'users_service': 'reachable'
            }), 200
        else:
            return jsonify({
                'status': 'degraded',
                'database': 'connected',
                'users_service': 'unreachable'
            }), 200
    except:
        return jsonify({'status': 'not ready'}), 503

# ==================== CRUD POSTS ====================

@app.route('/posts', methods=['GET'])
def get_posts():
    """GET tous les posts avec info utilisateur"""
    logger.info("📥 GET /posts")
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('''
            SELECT p.id, p.user_id, p.title, p.content, p.created_at,
                   u.name as user_name, u.email as user_email
            FROM posts p
            JOIN users u ON p.user_id = u.id
            ORDER BY p.created_at DESC
        ''')
        posts = cur.fetchall()
        cur.close()
        conn.close()
        
        logger.info(f"✅ Retourné {len(posts)} posts")
        return jsonify({'success': True, 'count': len(posts), 'posts': posts}), 200
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/posts/<int:post_id>', methods=['GET'])
def get_post(post_id):
    """GET un post par ID"""
    logger.info(f"📥 GET /posts/{post_id}")
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('''
            SELECT p.*, u.name as user_name, u.email as user_email
            FROM posts p
            JOIN users u ON p.user_id = u.id
            WHERE p.id = %s
        ''', (post_id,))
        post = cur.fetchone()
        cur.close()
        conn.close()
        
        if post:
            return jsonify({'success': True, 'post': post}), 200
        else:
            return jsonify({'success': False, 'error': 'Post not found'}), 404
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/posts/user/<int:user_id>', methods=['GET'])
def get_posts_by_user(user_id):
    """GET tous les posts d'un utilisateur"""
    logger.info(f"📥 GET /posts/user/{user_id}")
    
    # COMMUNICATION INTER-MICROSERVICES: Vérifier que l'user existe
    user_exists, user_data = verify_user_exists(user_id)
    if not user_exists:
        return jsonify({'success': False, 'error': 'User not found'}), 404
    
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('''
            SELECT id, user_id, title, content, created_at
            FROM posts
            WHERE user_id = %s
            ORDER BY created_at DESC
        ''', (user_id,))
        posts = cur.fetchall()
        cur.close()
        conn.close()
        
        logger.info(f"✅ Retourné {len(posts)} posts pour user {user_id}")
        return jsonify({
            'success': True,
            'count': len(posts),
            'user': user_data,
            'posts': posts
        }), 200
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/posts', methods=['POST'])
def create_post():
    """POST créer un post"""
    logger.info("📝 POST /posts")
    data = request.get_json()
    
    if not data or not data.get('user_id') or not data.get('title') or not data.get('content'):
        return jsonify({'success': False, 'error': 'user_id, title and content required'}), 400
    
    user_id = data['user_id']
    title = data['title'].strip()
    content = data['content'].strip()
    
    # COMMUNICATION INTER-MICROSERVICES: Vérifier que l'user existe
    user_exists, user_data = verify_user_exists(user_id)
    if not user_exists:
        return jsonify({'success': False, 'error': f'User {user_id} does not exist'}), 404
    
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            'INSERT INTO posts (user_id, title, content) VALUES (%s, %s, %s) RETURNING *',
            (user_id, title, content)
        )
        new_post = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        # Enrichir avec les données user
        new_post['user_name'] = user_data['name']
        new_post['user_email'] = user_data['email']
        
        logger.info(f"✅ Post créé: {new_post['id']} par user {user_id}")
        return jsonify({'success': True, 'post': new_post}), 201
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/posts/<int:post_id>', methods=['PUT'])
def update_post(post_id):
    """PUT mettre à jour un post"""
    logger.info(f"✏️ PUT /posts/{post_id}")
    data = request.get_json()
    
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400
    
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        updates = []
        values = []
        
        if data.get('title'):
            updates.append('title = %s')
            values.append(data['title'])
        if data.get('content'):
            updates.append('content = %s')
            values.append(data['content'])
        
        if not updates:
            return jsonify({'success': False, 'error': 'No fields to update'}), 400
        
        updates.append('updated_at = CURRENT_TIMESTAMP')
        values.append(post_id)
        
        query = f"UPDATE posts SET {', '.join(updates)} WHERE id = %s RETURNING *"
        
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(query, values)
        updated_post = cur.fetchone()
        
        if not updated_post:
            cur.close()
            conn.close()
            return jsonify({'success': False, 'error': 'Post not found'}), 404
        
        conn.commit()
        cur.close()
        conn.close()
        
        logger.info(f"✅ Post {post_id} mis à jour")
        return jsonify({'success': True, 'post': updated_post}), 200
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/posts/<int:post_id>', methods=['DELETE'])
def delete_post(post_id):
    """DELETE supprimer un post"""
    logger.info(f"🗑️ DELETE /posts/{post_id}")
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('DELETE FROM posts WHERE id = %s RETURNING *', (post_id,))
        deleted_post = cur.fetchone()
        
        if not deleted_post:
            cur.close()
            conn.close()
            return jsonify({'success': False, 'error': 'Post not found'}), 404
        
        conn.commit()
        cur.close()
        conn.close()
        
        logger.info(f"✅ Post {post_id} supprimé")
        return jsonify({'success': True, 'message': 'Post deleted', 'post': deleted_post}), 200
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== STATS ====================

@app.route('/posts/stats', methods=['GET'])
def stats():
    """Statistiques des posts"""
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('''
            SELECT 
                COUNT(*) as total_posts,
                COUNT(DISTINCT user_id) as users_with_posts
            FROM posts
        ''')
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        return jsonify({'success': True, 'stats': result}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/info', methods=['GET'])
def info():
    return jsonify({
        'service': 'posts-service',
        'version': '1.0.0',
        'description': 'Microservice pour la gestion des posts',
        'dependencies': {
            'users-service': USERS_SERVICE_URL
        },
        'endpoints': [
            'GET /posts',
            'GET /posts/<id>',
            'GET /posts/user/<user_id>',
            'POST /posts',
            'PUT /posts/<id>',
            'DELETE /posts/<id>',
            'GET /posts/stats'
        ]
    }), 200

if __name__ == '__main__':
    logger.info("🚀 Starting Posts Service on port 5002...")
    logger.info(f"🔗 Users Service URL: {USERS_SERVICE_URL}")
    app.run(host='0.0.0.0', port=5002, debug=False)
