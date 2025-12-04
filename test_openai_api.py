#!/usr/bin/env python3
"""
Test API OpenAI - Version Python
Installez d'abord: pip install requests
"""

import requests
import json
import sys

# 🔑 VOTRE CLÉ API
API_KEY = "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"

def test_openai_api(message="Bonjour, réponds en français avec une phrase courte."):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {API_KEY}'
    }

    payload = {
        "model": "gpt-4o-mini",
        "messages": [
            {
                "role": "system",
                "content": "Tu es un assistant qui répond toujours en français."
            },
            {
                "role": "user",
                "content": message
            }
        ],
        "max_tokens": 100,
        "temperature": 0.7
    }

    print(f"🧪 Test de l'API OpenAI...")
    print(f"Message: {message}")

    try:
        response = requests.post(
            "https://api.openai.com/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=30
        )

        if response.status_code == 200:
            data = response.json()
            print("✅ SUCCÈS!")
            print(f"Réponse: {data['choices'][0]['message']['content']}")
            print(f"Tokens utilisés: {data['usage']['total_tokens']}")
            return True
        else:
            print(f"❌ ERREUR API: {response.status_code}")
            print(f"Détails: {response.text}")
            
            if response.status_code == 401:
                print("🔑 Clé API invalide ou expirée")
            elif response.status_code == 429:
                print("⏰ Limite de taux dépassée")
            elif response.status_code == 402:
                print("💳 Quota dépassé ou facturation requise")
            
            return False

    except requests.exceptions.RequestException as e:
        print(f"❌ ERREUR RÉSEAU: {e}")
        return False
    except json.JSONDecodeError as e:
        print(f"❌ ERREUR JSON: {e}")
        return False

if __name__ == "__main__":
    # Test avec message personnalisé si fourni
    test_message = sys.argv[1] if len(sys.argv) > 1 else "Bonjour, réponds en français avec une phrase courte."
    test_openai_api(test_message)
