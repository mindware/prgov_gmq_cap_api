echo "Test"
curl -u cap_admin:c4b2c01599ec02c69a1178be9baf3af1 -d {"first_name" : "Andrés", "last_name" : "Colón", "mother_last_name" : "Pérez", "ssn" : "111-22-3333", "license" : "12345678", "birth_date" : "01/01/1982", "residency" : "San Juan", "IP" : "192.168.1.2", "reason" : "Because I can", "birth_place" : "San Juan"} -i -X POST 'http://localhost:9000/v1/cap/transaction/'
echo ""
