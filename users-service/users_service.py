from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration DB
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'postgres-service'),
    'port': os.environ.get('DB_PORT', '5432'),
    'database': os.environ.get('DB_NAME', 'microservices_db'),
    'user': os.environ.get('DB_USER', 'appuser'),
    'password': os.environ.get('DB_PASSWORD', 'password')
}

def get_db():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logger.error(f"DB Error: {e}")
        return None

# ==================== HEALTH ====================

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'users-service'}), 200

@app.route('/ready', methods=['GET'])
def ready():
    conn = get_db()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute('SELECT 1')
            cur.close()
            conn.close()
            return jsonify({'status': 'ready', 'database': 'connected'}), 200
        except:
            return jsonify({'status': 'not ready'}), 503
    return jsonify({'status': 'not ready'}), 503

# ==================== CRUD USERS ====================

@app.route('/users', methods=['GET'])
def get_users():
    """GET tous les utilisateurs"""
    logger.info("📥 GET /users")
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT id, name, email, created_at FROM users ORDER BY created_at DESC')
        users = cur.fetchall()
        cur.close()
        conn.close()
        
        logger.info(f"✅ Retourné {len(users)} utilisateurs")
        return jsonify({'success': True, 'count': len(users), 'users': users}), 200
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """GET un utilisateur par ID"""
    logger.info(f"📥 GET /users/{user_id}")
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT id, name, email, created_at FROM users WHERE id = %s', (user_id,))
        user = cur.fetchone()
        cur.close()
        conn.close()
        
        if user:
            logger.info(f"✅ User {user_id} trouvé")
            return jsonify({'success': True, 'user': user}), 200
        else:
            return jsonify({'success': False, 'error': 'User not found'}), 404
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/users', methods=['POST'])
def create_user():
    """POST créer un utilisateur"""
    logger.info("📝 POST /users")
    data = request.get_json()
    
    if not data or not data.get('name') or not data.get('email'):
        return jsonify({'success': False, 'error': 'Name and email required'}), 400
    
    name = data['name'].strip()
    email = data['email'].strip()
    
    if '@' not in email:
        return jsonify({'success': False, 'error': 'Invalid email'}), 400
    
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            'INSERT INTO users (name, email) VALUES (%s, %s) RETURNING id, name, email, created_at',
            (name, email)
        )
        new_user = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        logger.info(f"✅ User créé: {new_user['id']}")
        return jsonify({'success': True, 'user': new_user}), 201
    except psycopg2.IntegrityError:
        return jsonify({'success': False, 'error': 'Email already exists'}), 409
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    """PUT mettre à jour un utilisateur"""
    logger.info(f"✏️ PUT /users/{user_id}")
    data = request.get_json()
    
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400
    
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        updates = []
        values = []
        
        if data.get('name'):
            updates.append('name = %s')
            values.append(data['name'])
        if data.get('email'):
            updates.append('email = %s')
            values.append(data['email'])
        
        if not updates:
            return jsonify({'success': False, 'error': 'No fields to update'}), 400
        
        updates.append('updated_at = CURRENT_TIMESTAMP')
        values.append(user_id)
        
        query = f"UPDATE users SET {', '.join(updates)} WHERE id = %s RETURNING id, name, email, updated_at"
        
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(query, values)
        updated_user = cur.fetchone()
        
        if not updated_user:
            cur.close()
            conn.close()
            return jsonify({'success': False, 'error': 'User not found'}), 404
        
        conn.commit()
        cur.close()
        conn.close()
        
        logger.info(f"✅ User {user_id} mis à jour")
        return jsonify({'success': True, 'user': updated_user}), 200
    except psycopg2.IntegrityError:
        return jsonify({'success': False, 'error': 'Email already exists'}), 409
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    """DELETE supprimer un utilisateur"""
    logger.info(f"🗑️ DELETE /users/{user_id}")
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('DELETE FROM users WHERE id = %s RETURNING id, name, email', (user_id,))
        deleted_user = cur.fetchone()
        
        if not deleted_user:
            cur.close()
            conn.close()
            return jsonify({'success': False, 'error': 'User not found'}), 404
        
        conn.commit()
        cur.close()
        conn.close()
        
        logger.info(f"✅ User {user_id} supprimé")
        return jsonify({'success': True, 'message': 'User deleted', 'user': deleted_user}), 200
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== STATS ====================

@app.route('/users/stats', methods=['GET'])
def stats():
    """Statistiques des utilisateurs"""
    conn = get_db()
    if not conn:
        return jsonify({'success': False, 'error': 'DB connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT COUNT(*) as total FROM users')
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        return jsonify({'success': True, 'stats': result}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/info', methods=['GET'])
def info():
    return jsonify({
        'service': 'users-service',
        'version': '1.0.0',
        'description': 'Microservice pour la gestion des utilisateurs',
        'endpoints': [
            'GET /users',
            'GET /users/<id>',
            'POST /users',
            'PUT /users/<id>',
            'DELETE /users/<id>',
            'GET /users/stats'
        ]
    }), 200

if __name__ == '__main__':
    logger.info("🚀 Starting Users Service on port 5001...")
    app.run(host='0.0.0.0', port=5001, debug=False)
