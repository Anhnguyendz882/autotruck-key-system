const express = require("express")
const fs = require("fs")
const axios = require("axios")
const path = require("path")

const app = express()

const ADMIN_KEY = "AT_ADMIN_999"

app.use(express.static("web"))

function loadDB(){
 return JSON.parse(fs.readFileSync("./database/keys.json"))
}

function saveDB(db){
 fs.writeFileSync("./database/keys.json",JSON.stringify(db,null,2))
}

function genKey(name){
 const rand=Math.random().toString(36).substring(2,6).toUpperCase()
 return `AT-${name.toUpperCase()}-${rand}`
}

app.get("/admin-login",(req,res)=>{

 const key=req.query.key

 if(key===ADMIN_KEY){
  return res.json({status:"success"})
 }

 res.json({status:"invalid"})
})

app.get("/create-key",(req,res)=>{

 const admin=req.query.admin
 const ingame=req.query.ingame

 if(admin!==ADMIN_KEY){
  return res.json({status:"no_admin"})
 }

 const db=loadDB()

 const key=genKey(ingame)

 db[key]={
  ingame:ingame,
  status:"active",
  created:Date.now()
 }

 saveDB(db)

 res.json({
  status:"created",
  key:key
 })
})

app.get("/verify",async(req,res)=>{

 const key=req.query.key
 const name=req.query.name

 const db=loadDB()

 if(!db[key]){
  return res.json({status:"invalid"})
 }

 if(db[key].ingame!==name){
  return res.json({status:"wrong_name"})
 }

 if(db[key].status!=="active"){
  return res.json({status:"disabled"})
 }

 try{

  const script=await axios.get(
   "https://raw.githubusercontent.com/YOUR_GITHUB/AutoTruck.lua"
  )

  res.json({
   status:"success",
   code:script.data
  })

 }catch(e){

  res.json({status:"error"})

 }

})

app.listen(3000,()=>{
 console.log("API running")
})