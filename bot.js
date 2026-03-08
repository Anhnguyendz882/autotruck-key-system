const {Client,GatewayIntentBits}=require("discord.js")
const fs=require("fs")

const client=new Client({
 intents:[
  GatewayIntentBits.Guilds,
  GatewayIntentBits.GuildMessages,
  GatewayIntentBits.MessageContent
 ]
})

const TOKEN=process.env.DISCORD_TOKEN

function random(){
 return Math.random().toString(36).substring(2,6).toUpperCase()
}

function genKey(name){
 return `AT-${name.toUpperCase()}-${random()}`
}

client.on("messageCreate",msg=>{

 if(!msg.content.startsWith(".taokey")) return

 const args=msg.content.split(" ")

 const ingame=args[1]

 if(!ingame){
  msg.reply("Nhap ten ingame")
  return
 }

 const key=genKey(ingame)

 let db={}

 if(fs.existsSync("./database/keys.json")){
  db=JSON.parse(fs.readFileSync("./database/keys.json"))
 }

 db[key]={
  ingame:ingame,
  status:"active",
  created:Date.now()
 }

 fs.writeFileSync("./database/keys.json",JSON.stringify(db,null,2))

 msg.reply(`KEY: ${key}`)
})

client.login(TOKEN)
