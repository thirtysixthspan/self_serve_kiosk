Self_Service_Kiosk
==================

A self-service kiosk interface accepting credit card payments via card swipe implemented in Ruby.

Features
--------
* AES and Private/Public keypair encryption of credit card swipe data using the magtek_card_reader gem
* Payment processing using the Stripe API
* HTTP API for processing customer data using clients
* Admin interface for inspecting and modifying invoice and transaction data
* Unit and Integration tests using RSPEC and Capybara
* ORM wrapping data storage in Redis
* Deployment via Capistrano

Requires
--------

* Web server and Redis database
* Internet connected computer to use as kiosk
* A magtek credit card reader
* Stripe account

Notes
-----
 This code was extracted from that written to provide a self service kioski for the sale of drinks, snacks, and coffee 
at The 404 coworking facility in Oklahoma City, Oklahoma. The application provides membership and event functionality
as well as a self-service kiosk. 

License
-------
Copyright (c) 2013 Derrick Parkhurst (derrick.parkhurst@gmail.com)

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

