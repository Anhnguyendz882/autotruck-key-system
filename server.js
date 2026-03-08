const express = require("express")
const fs = require("fs")
const path = require("path")

const app = express()

app.use(express.json())

// cho phép load file html/css/js
app.use(express.static(__dirname))

// trang chủ
app.get("/", (req,res)=>{
 res.sendFile(path.join(__dirname,"index.html"))
})

// API lấy danh sách key
app.get("/keys",(req,res)=>{
 const data = JSON.parse(fs.readFileSync("keys.json"))
 res.json(data)
})

const PORT = process.env.PORT || 3000

app.listen(PORT,()=>{
 console.log("Server running on port "+PORT)
})
