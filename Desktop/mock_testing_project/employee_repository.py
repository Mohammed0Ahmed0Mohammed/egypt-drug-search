import requests

class EmployeeRepository:
    BASE_URL = "https://api.example.com/employees"

    def get_employees(self):
        response = requests.get(self.BASE_URL)
        if response.status_code != 200:
            raise RuntimeError(f"API error: status {response.status_code}")
        employees = response.json()
        return sorted(employees, key=lambda x: x["id"])
