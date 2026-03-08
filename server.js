const express = require("express")
const fs = require("fs")
const path = require("path")

const app = express()

app.use(express.json())
app.use(express.static(__dirname))

app.get("/",(req,res)=>{
 res.sendFile(path.join(__dirname,"index.html"))
})

app.get("/keys",(req,res)=>{

 if(!fs.existsSync("keys.json")){
  fs.writeFileSync("keys.json","[]")
 }

 const data = JSON.parse(fs.readFileSync("keys.json"))
 res.json(data)
})

app.post("/verify",(req,res)=>{

 const {key} = req.body

 const data = JSON.parse(fs.readFileSync("keys.json"))

 const found = data.find(k=>k.key===key)

 if(!found){
  return res.json({status:false})
 }

 res.json({status:true})
})

const PORT = process.env.PORT || 10000

app.listen(PORT,()=>{
 console.log("Server running on "+PORT)
})

require("./bot.js")
