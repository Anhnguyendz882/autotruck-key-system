const express = require("express")
const fs = require("fs")
const path = require("path")

const app = express()

app.use(express.json())
app.use(express.static(__dirname))

// trang web
app.get("/", (req,res)=>{
 res.sendFile(path.join(__dirname,"index.html"))
})

// lấy danh sách key
app.get("/keys",(req,res)=>{

 if(!fs.existsSync("keys.json")){
  fs.writeFileSync("keys.json","[]")
 }

 const data = JSON.parse(fs.readFileSync("keys.json"))
 res.json(data)
})

// verify key
app.post("/verify",(req,res)=>{

 const {key,player} = req.body

 if(!fs.existsSync("keys.json")){
  return res.json({status:false,msg:"No keys"})
 }

 const data = JSON.parse(fs.readFileSync("keys.json"))

 const found = data.find(k=>k.key === key)

 if(!found){
  return res.json({status:false,msg:"Invalid key"})
 }

 if(found.player && found.player !== player){
  return res.json({status:false,msg:"Wrong player"})
 }

 const now = Math.floor(Date.now()/1000)

 if(found.expire && now > found.expire){
  return res.json({status:false,msg:"Key expired"})
 }

 res.json({status:true,msg:"Key valid"})
})

const PORT = process.env.PORT || 10000

app.listen(PORT,()=>{
 console.log("Server running on "+PORT)
})

// chạy discord bot
require("./bot.js")
