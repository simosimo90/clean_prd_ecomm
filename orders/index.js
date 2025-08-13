
'use strict';

// Import your individual service files

const orService1 = require('./ord-service1');
const orService2 = require('./ord-service2');
const orService3 = require('./ord-service3');


exports.handler = async function (event, context) {
    // Log the incoming event for debugging purposes in CloudWatch Logs
    console.log('Received event:', JSON.stringify(event, null, 2));

    // Extract relevant information from the API Gateway event
    // For HTTP API Gateway proxy integration, rawPath and requestContext.http are standard
    const path = event.rawPath;
    const httpMethod = event.requestContext.http.method;

    let response;

    try {
        // Implement your routing logic here
        // You can use if/else if, a switch statement, or a more sophisticated router library
        if (path === '/orders/service1' && httpMethod === 'GET') {
            // Call the handler function from or-service1.js
            // The callback parameter is often not strictly needed for async handlers,
            // but including it matches the original signature.
            response = await orService1.handler(event, context, () => {});
        } else if (path === '/orders/service2' && httpMethod === 'GET') {
            response = await orService2.handler(event, context, () => {});
        } else if (path === '/orders/service3' && httpMethod === 'GET') {
            response = await orService3.handler(event, context, () => {});
        } else {
            // If no route matches, return a 404 Not Found
            response = {
                statusCode: 404,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: `Route not found: ${httpMethod} ${path}` }),
            };
        }
    } catch (error) {
        // Catch any errors during routing or service execution
        console.error('Error in Lambda router or service:', error);
        response = {
            statusCode: 500,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ message: 'Internal Server Error', error: error.message }),
        };
    }

    // Ensure the response body is a string for API Gateway proxy integration
    // If your individual service handlers return a non-string body (e.g., an object), stringify it.
    if (typeof response.body !== 'string') {
        response.body = JSON.stringify(response.body);
    }

    return response; // Return the final response object to API Gateway
};