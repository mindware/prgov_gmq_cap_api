Good Standing Certificate API
------------------------------

This is a RESTful API component of the Government Messaging Queue, an asynchronous, inter-government messaging system used for generating a good standing certificate. 

This system allows requests from the web application to be processed asynchronously, such as to: 
- request jobs to send emails
- validate and save transactions
- communicate with the criminal justice information system of the DOJ and Police Department in order to validate citizen identity and criminal records.
- allow the asynchrous delivery of certificates
- validate existing government certificates 

Stack:
-----
This is a RESTful API built with Ruby, using the Grape gem. It has an authentication system, allows for modifying the configuration without rebooting the server, it has tools to generate passwords securely, and has a myriad of endpoints that have been detailed in documents delivered to government personnel at Puerto Rico's OMB, PRPD and DOJ. 

Requirements:
* Install ruby > 2.0
* Install rubygems

To start the Server:
* bundle install
* foreman start


Regarding the use of the Redis Gems:
We use Redis-rb, whose synchrony driver adds support for em-synchrony. This makes redis-rb work with EventMachine's asynchronous I/O, while not changing the exposed API. The hiredis gem needs to be available as well, because the synchrony driver uses hiredis for parsing the Redis protocol.

License:
--------
The MIT License (MIT)

Copyright (c) 2015 - Government of Puerto Rico

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
