import unittest
from unittest.mock import patch, Mock
from employee_repository import EmployeeRepository

SAMPLE_DATA = [
    {"id": 3, "name": "Alice", "position": "Developer"},
    {"id": 1, "name": "Bob", "position": "Manager"},
    {"id": 2, "name": "Charlie", "position": "Designer"},
]

class TestEmployeeRepository(unittest.TestCase):

    @patch('requests.get')
    def test_successful_retrieval_returns_list(self, mock_get):
        mock_resp = Mock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = SAMPLE_DATA.copy()
        mock_get.return_value = mock_resp

        repo = EmployeeRepository()
        result = repo.get_employees()

        self.assertIsInstance(result, list)
        self.assertEqual(len(result), 3)

    @patch('requests.get')
    def test_sorting_by_id_ascending(self, mock_get):
        mock_resp = Mock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = SAMPLE_DATA.copy()
        mock_get.return_value = mock_resp

        repo = EmployeeRepository()
        result = repo.get_employees()

        expected_order = [
            {"id": 1, "name": "Bob", "position": "Manager"},
            {"id": 2, "name": "Charlie", "position": "Designer"},
            {"id": 3, "name": "Alice", "position": "Developer"},
        ]
        self.assertEqual(result, expected_order)

    @patch('requests.get')
    def test_error_handling_non_200_raises(self, mock_get):
        mock_resp = Mock()
        mock_resp.status_code = 500
        mock_get.return_value = mock_resp

        repo = EmployeeRepository()
        with self.assertRaises(RuntimeError) as ctx:
            repo.get_employees()
        self.assertIn("status 500", str(ctx.exception))

if __name__ == "__main__":
    unittest.main()
