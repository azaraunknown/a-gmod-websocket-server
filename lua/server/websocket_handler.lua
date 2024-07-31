-- Load the GWSockets module
require( "gwsockets" )
-- Server IP and port details
local server_ip = false -- REDACTED
local port = false -- REDACTED
-- Create the WebSocket URL using the server IP and port
local url = "ws://" .. server_ip .. ":" .. port
-- Create a WebSocket object
local socket = GWSockets.createWebSocket( url )
-- Initialize the GWSVR table if it doesn't already exist
GWSVR = GWSVR or {}
-- Define the action to take when a message is received on the WebSocket
function socket:onMessage( data )
    -- Convert the JSON data to a Lua table
    local data = util.JSONToTable( data )
    print( "[WSS] Debugging:", GWSVR.ACCESS_KEY )
    -- Check if the data is a table and contains the necessary fields
    if not istable( data ) then return end
    if not data.cmd then return end
    if not data.key then return end
    -- Verify the access key
    if not ( data.key == GWSVR.ACCESS_KEY ) then
        print( "[WSS] [CRITICAL] Command requested with incorrect key" )
        return
    end

    -- Function to split the command string into arguments
    local function splitString( inputstr, sep )
        if sep == nil then sep = "%s" end
        local t = {}
        for str in string.gmatch( inputstr, "([^" .. sep .. "]+)" ) do
            table.insert( t, str )
        end
        return t
    end

    -- Split the command string and run the console command with the arguments
    local args = splitString( data.cmd, " " )
    RunConsoleCommand( unpack( args ) )
    -- Refresh the access key after running the command
    DBD.RefreshKey()
end

-- Define the action to take when there is an error with the WebSocket
function socket:onError( txt )
    print( "Error:", txt )
end

-- Define the action to take when the WebSocket is successfully connected
function socket:onConnected()
    print( "WebSocket connected" )
end

-- Define the action to take when the WebSocket is disconnected
function socket:onDisconnected()
    print( "WebSocket disconnected" )
end

-- Open the WebSocket connection
socket:open()