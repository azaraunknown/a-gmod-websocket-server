-- Load the MySQLOO module
require( "mysqloo" )
-- Initialize the DBD table if it doesn't already exist
DBD = DBD or {}
-- Database connection details
DBD.HOST = false --REDACTED 
DBD.PORT = false --REDACTED
DBD.USER = false --REDACTED
DBD.PASS = false --REDACTED
DBD.DB = false --REDACTED
-- Create a connection object using the database details
local db = mysqloo.connect( DBD.HOST, DBD.USER, DBD.PASS, DBD.DB, DBD.PORT )
-- Define the action to take when the connection is successfully established
db.onConnected = function() print( "[WSS] Connection to Database Established" ) end
-- Define the action to take if the connection fails
db.onConnectionFailed = function( _, error ) print( "[WSS] Connection to Database Failed:", error ) end
-- Initiate the connection to the database
db:connect()
-- Create the 'websocket_auth' table if it doesn't exist
local query = db:query( "CREATE TABLE IF NOT EXISTS websocket_auth( access_key TEXT )" )
query:start()
-- Query to select all entries from the 'websocket_auth' table
local query = db:query( "SELECT * FROM websocket_auth" )
query.onSuccess = function( _, data )
    if data and data[ 1 ] then
        -- If there is data, set the access key
        GWSVR.ACCESS_KEY = data[ 1 ].access_key
    else
        -- If there is no data, initialize the access key to an empty string and insert it into the table
        GWSVR.ACCESS_KEY = ""
        local query = db:query( "INSERT INTO websocket_auth( access_key ) VALUES( '' )" )
        query:start()
    end
end

-- Start the query to retrieve the access key
query:start()
-- Create a timer to refresh the access key every 300 seconds (5 minutes)
timer.Create( "DBD.AccessKey", 300, 0, function()
    local key_length = math.random( 100, 160 )
    print( "[WSS] Disposing of old access key." )
    print( "[WSS] Generating new access key." )
    local key = ""
    -- Generate a new access key of random length between 100 and 160 characters
    for i = 1, key_length do
        local char_type = math.random( 1, 3 )
        if char_type == 1 then
            -- Digits 0-9
            key = key .. string.char( math.random( 48, 57 ) )
        elseif char_type == 2 then
            -- Uppercase letters A-Z
            key = key .. string.char( math.random( 65, 90 ) )
        else
            -- Lowercase letters a-z
            key = key .. string.char( math.random( 97, 122 ) )
        end
    end

    -- Update the global access key variable
    GWSVR.ACCESS_KEY = key
    -- Update the access key in the database
    local query = db:query( "UPDATE websocket_auth SET access_key = '" .. key .. "'" )
    query:start()
end )

-- Function to manually refresh the access key
function DBD.RefreshKey()
    local key_length = math.random( 100, 160 )
    print( "[WSS] Disposing of old access key." )
    print( "[WSS] Generating new access key." )
    local key = ""
    -- Generate a new access key of random length between 100 and 160 characters
    for i = 1, key_length do
        key = key .. string.char( math.random( 48, 122 ) )
    end

    -- Update the global access key variable
    GWSVR.ACCESS_KEY = key
    -- Update the access key in the database
    local query = db:query( "UPDATE websocket_auth SET access_key = '" .. key .. "'" )
    query:start()
end