const express=require("express")
const fs=require("fs")

const app=express()
app.use(express.json())

const DB="keys.json"

app.post("/check",(req,res)=>{

  const {key,username,hwid}=req.body

  const data=JSON.parse(fs.readFileSync(DB))

  const info=data[key]

  if(!info){
    return res.json({status:"invalid"})
  }

  if(info.user!==username){
    return res.json({status:"wrong_user"})
  }

  if(Date.now()>info.expire){
    return res.json({status:"expired"})
  }

  if(info.hwid==null){

    info.hwid=hwid
    fs.writeFileSync(DB,JSON.stringify(data,null,2))

  }else if(info.hwid!==hwid){

    return res.json({status:"shared_key"})
  }

  const script=fs.readFileSync("AutoTruck_v9.lua","utf8")

  res.json({
    status:"success",
    script:script
  })

})

app.listen(3000,()=>{

  console.log("API RUNNING")

})
