const express = require("express")
const fs = require("fs")
const path = require("path")

const app = express()

app.use(express.json())

// cho phép load file web
app.use(express.static("web"))

// trang chủ
app.get("/", (req,res)=>{
 res.sendFile(path.join(__dirname,"../web/index.html"))
})

// API lấy danh sách key
app.get("/keys",(req,res)=>{
 const data = JSON.parse(fs.readFileSync("keys.json"))
 res.json(data)
})

app.listen(3000,()=>{
 console.log("Server running")
})
