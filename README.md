# GWSVR WebSocket Integration

## Overview

This project demonstrates how to integrate MySQL and WebSocket functionalities in Garry's Mod using the MySQLOO and GWSockets libraries. It includes scripts to handle database connections, manage access keys, and execute commands via WebSocket communication.

# Files

1. db.lua
   This script handles the MySQL database connection and manages the access keys.

## Code Breakdown

- Dependencies and Initialization:
```lua
require("mysqloo")
DBD = DBD or {}
DBD.HOST = --REDACTED
DBD.PORT = --REDACTED
DBD.USER = --REDACTED
DBD.PASS = --REDACTED
DBD.DB = --REDACTED
```

- Database Connection:
```lua
local db = mysqloo.connect(DBD.HOST, DBD.USER, DBD.PASS, DBD.DB, DBD.PORT)
db.onConnected = function()
    print("[WSS] Connection to Database Established")
end
db.onConnectionFailed = function(_, error)
    print("[WSS] Connection to Database Failed:", error)
end
db:connect()
```

- Table Creation and Initial Data Retrieval:
```lua
local query = db:query("CREATE TABLE IF NOT EXISTS websocket_auth( access_key TEXT )")
query:start()

local query = db:query("SELECT * FROM websocket_auth")
query.onSuccess = function(_, data)
    if data and data[1] then
        GWSVR.ACCESS_KEY = data[1].access_key
    else
        GWSVR.ACCESS_KEY = ""
        local query = db:query("INSERT INTO websocket_auth( access_key ) VALUES( '' )")
        query:start()
    end
end
query:start()
```

- Access Key Management:
```lua
timer.Create("DBD.AccessKey", 300, 0, function()
    local key_length = math.random(100, 160)
    print("[WSS] Disposing of old access key.")
    print("[WSS] Generating new access key.")
    local key = ""
    for i = 1, key_length do
        local char_type = math.random(1, 3)
        if char_type == 1 then
            key = key .. string.char(math.random(48, 57))
        elseif char_type == 2 then
            key = key .. string.char(math.random(65, 90))
        else
            key = key .. string.char(math.random(97, 122))
        end
    end

    GWSVR.ACCESS_KEY = key
    local query = db:query("UPDATE websocket_auth SET access_key = '" .. key .. "'")
    query:start()
end)

function DBD.RefreshKey()
    local key_length = math.random(100, 160)
    print("[WSS] Disposing of old access key.")
    print("[WSS] Generating new access key.")
    local key = ""
    for i = 1, key_length do
        key = key .. string.char(math.random(48, 122))
    end

    GWSVR.ACCESS_KEY = key
    local query = db:query("UPDATE websocket_auth SET access_key = '" .. key .. "'")
    query:start()
end
```

2. socket.lua
   This script sets up the WebSocket connection and handles incoming messages and errors.
   Code Breakdown

- Dependencies and Initialization:
```lua
require("gwsockets")
local server_ip = false -- REDACTED
local port = false -- REDACTED
local url = "ws://" .. server_ip .. ":" .. port
local socket = GWSockets.createWebSocket(url)
GWSVR = GWSVR or {}
```

- WebSocket Event Handling:
```lua
function socket:onMessage(data)
    local data = util.JSONToTable(data)
    print("[WSS] Debugging:", GWSVR.ACCESS_KEY)
    if not istable(data) then return end
    if not data.cmd then return end
    if not data.key then return end
    if not (data.key == GWSVR.ACCESS_KEY) then
        print("[WSS] [CRITICAL] Command requested with incorrect key")
        return
    end

    local function splitString(inputstr, sep)
        if sep == nil then sep = "%s" end
        local t = {}
        for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
            table.insert(t, str)
        end
        return t
    end

    local args = splitString(data.cmd, " ")
    RunConsoleCommand(unpack(args))
    DBD.RefreshKey()
end

function socket:onError(txt)
    print("Error:", txt)
end

function socket:onConnected()
    print("WebSocket connected")
end

function socket:onDisconnected()
    print("WebSocket disconnected")
end
```

- Open WebSocket Connection:
```lua
socket:open()
```

How It Ties Together

1. _Database Connection_: The db.lua script establishes a connection to the MySQL database using the MySQLOO library. It creates the websocket_auth table if it doesn't exist and manages access keys that are used to authenticate WebSocket commands.

2. _Access Key Management_: The db.lua script periodically generates new access keys and updates the database. It also provides a manual method to refresh the access key.

3. _WebSocket Communication_: The socket.lua script sets up a WebSocket connection to a specified server. It handles incoming messages, verifies the access key, splits the command string, and executes the command. It also handles WebSocket errors and connection events.

4. _Integration_: The access key generated and managed by the db.lua script is used to authenticate commands received through the WebSocket connection in the socket.lua script. This ensures that only authorized commands are executed, adding a layer of security to the system.

# Usage

1. _Setup_: Ensure that the MySQLOO and GWSockets libraries are installed and properly set up in your Garry's Mod environment.
2. _Configuration_: Replace the `--REDACTED` placeholders in the scripts with your actual database and server details.
3. _Run_: Place the `db.lua` and `socket.lua` scripts in the appropriate directory and run your Garry's Mod server. The scripts will handle the database connection, WebSocket communication, and access key management automatically.

# Contributing

Feel free to open issues or submit pull requests if you find any bugs or have suggestions for improvements.

# License

This project is licensed under the MIT License. See the [LICENSE](license.md) file for details.
