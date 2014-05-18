echo "Trying valid user."
curl -u policia:password -X GET 'http://localhost:9000/v1/cap/transaction/1'
echo ""
echo ""
echo "Trying invalid user."
curl -u policia2:password -X GET 'http://localhost:9000/v1/cap/' -i
echo ""
echo ""
echo "Trying transaction. Checking entities."
curl -u andres:password -X GET 'http://localhost:9000/v1/cap/transaction/1' 
echo ""
