const API=""

function login(){

 let key=document.getElementById("adminkey").value

 fetch(`/admin-login?key=${key}`)
 .then(res=>res.json())
 .then(data=>{

  if(data.status==="success"){

   localStorage.setItem("admin",key)

   window.location="dashboard.html"

  }else{

   document.getElementById("result").innerText="Sai key"

  }

 })
}

function createKey(){

 let ingame=document.getElementById("ingame").value
 let admin=localStorage.getItem("admin")

 fetch(`/create-key?admin=${admin}&ingame=${ingame}`)
 .then(res=>res.json())
 .then(data=>{

  if(data.status==="created"){

   document.getElementById("keyresult").innerText=data.key

  }else{

   document.getElementById("keyresult").innerText="Error"

  }

 })
}