require("./bot")

const express = require("express")
const fs = require("fs")

const app = express()
app.use(express.json())

const KEY_FILE = "./keys.json"

if (!fs.existsSync(KEY_FILE)) {
  fs.writeFileSync(KEY_FILE, "{}")
}

app.get("/", (req,res)=>{
  res.send("API KEY SYSTEM RUNNING")
})

app.get("/check", (req,res)=>{
  const key = req.query.key
  const ingame = req.query.ingame

  if(!key || !ingame){
    return res.json({status:false,msg:"missing key or ingame"})
  }

  const keys = JSON.parse(fs.readFileSync(KEY_FILE))

  if(!keys[key]){
    return res.json({status:false,msg:"invalid key"})
  }

  if(keys[key].ingame !== ingame){
    return res.json({status:false,msg:"wrong ingame"})
  }

  res.json({status:true})
})

const PORT = process.env.PORT || 3000

app.listen(PORT, ()=>{
  console.log("API KEY SYSTEM RUNNING")
})
