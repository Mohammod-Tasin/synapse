import requests

BASE_URL = "http://localhost:8000/api/v1"

def test_endpoint(endpoint):
    headers = {"Authorization": "Bearer INVALID_TOKEN"}
    try:
        response = requests.get(f"{BASE_URL}{endpoint}", headers=headers)
        print(f"GET {endpoint} - Status: {response.status_code}")
        if response.status_code == 401:
            print(f"✅ Success: {endpoint} correctly returned 401 Unauthorized")
        else:
            print(f"❌ Failure: {endpoint} returned {response.status_code} instead of 401")
    except Exception as e:
        print(f"Error testing {endpoint}: {e}")

if __name__ == "__main__":
    print("Starting Security Audit Test...")
    test_endpoint("/leaderboard")
    test_endpoint("/stats/me/today")
    test_endpoint("/stats/me/analytics")
    test_endpoint("/onboarding")
    print("Security Audit Test Complete.")
