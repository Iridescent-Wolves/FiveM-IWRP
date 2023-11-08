---@meta
---EmmyLua Annotations / VSCode Lua Language Server
---https://marketplace.visualstudio.com/items?itemName=sumneko.lua

---@param Query string
---@param Parameters? table | fun(Result: number)
---@param Callback? fun(AffectedRows: number)
function MySQL.Update(Query, Parameters, Callback)
end
MySQL.Async.Execute = MySQL.Update

---@param Query string
---@param Parameters? table
---@return number AffectedRows
function MySQL.Update.Await(Query, Parameters)
end
MySQL.Sync.Execute = MySQL.Update.Await

---@class Result
---@field AffectedRows number?
---@field FieldCount number?
---@field Info string?
---@field InsertID number?
---@field ServerStatus number?
---@field WarningStatus number?
---@field ChangedRows number?

---@param Query string
---@param Parameters? table | fun(Result: Result | table<number, table<string, unknown>> | nil)
---@param Callback? fun(Result: Result | table<number, table<string, unknown>> | nil)
function MySQL.Query(Query, Parameters, Callback)
end
MySQL.Async.FetchAll = MySQL.Query

---@param Query string
---@param Parameters? table
---@return Result | table<number, table<string, unknown>> | nil Result
function MySQL.Query.Await(Query, Parameters)
end
MySQL.Sync.FetchAll = MySQL.Query.Await


---@param Query string
---@param Parameters? table | fun(Column: unknown | nil)
---@param Callback? fun(Column: unknown | nil)
function MySQL.Scalar(Query, Parameters, Callback)
end
MySQL.Async.FetchScalar = MySQL.Scalar


---@param Query string
---@param Parameters? table
---@return unknown | nil Column
function MySQL.Scalar.Await(Query, Parameters)
end
MySQL.Sync.FetchScalar = MySQL.Scalar.Await

---@param Query string
---@param Parameters? table | fun(Row: table<string, unknown> | nil)
---@param Callback? fun(Row: table<string, unknown> | nil)
function MySQL.Single(Query, Parameters, Callback)
end
MySQL.Async.FetchSingle = MySQL.Single

---@param Query string
---@param Parameters? table
---@return table<string, unknown> | nil Row
function MySQL.Single.Await(Query, Parameters)
end
MySQL.Sync.FetchSingle = MySQL.Single.Await

---@param Query string
---@param Parameters? table | fun(InsertID: number)
---@param Callback? fun(InsertID: number)
function MySQL.Insert(Query, Parameters, Callback)
end
MySQL.Async.Insert = MySQL.Insert

---@param Query string
---@param Parameters? table
---@return number InsertID
function MySQL.Insert.Await(Query, Parameters)
end
MySQL.Sync.Insert = MySQL.Insert.Await

---@param Queries table
---@param Parameters? table | fun(Success: boolean)
---@param Callback? fun(Success: boolean)
function MySQL.Transaction(Queries, Parameters, Callback)
end
MySQL.Async.Transaction = MySQL.Transaction

---@param Queries table
---@param Parameters? table
---@return boolean Success
function MySQL.Transaction.Await(Queries, Parameters)
end
MySQL.Sync.Transaction = MySQL.Transaction.Await

---@param Query string
---@param Parameters table
---@param Callback? fun(Result: unknown | nil)
function MySQL.Prepare(Query, Parameters, Callback)
end
MySQL.Async.Prepare = MySQL.Prepare

---@param Query string
---@param Parameters table
---@return unknown | nil Result
function MySQL.Prepare.Await(Query, Parameters)
end
MySQL.Sync.Prepare = MySQL.Prepare.Await
