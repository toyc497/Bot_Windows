let chavesView = document.querySelector("#chavesView");
let outputView = document.querySelector("#outputView");

/* PEDACOS DA STRING SQL */

const cmdSqlInicial = "INSERT INTO general_keys (idkey,keycontent,serialcontent,keystate,bancada,disco,memoria) VALUES ";
const cmdSqlFinal = ";";
const shapeInicial = "(default,'";
const shapeFinal = "','',0,'',0,0)";

/*........*/

let shapeAux = "";

function concatenaShapeChave(vetorKeys){
    let shapeConcatenado = null;

    for(let i=0; i < vetorKeys.length; i++){
        shapeConcatenado = `${shapeInicial}${vetorKeys[i]}${shapeFinal}`;
        shapeAux = `${shapeAux}${shapeConcatenado},`;
    }
    
    shapeAux = shapeAux.substring(0,shapeAux.length - 1);
}

function inputParaVetorChaves(inputChaves){
    const chaves = inputChaves;
    const vetorChaves = chaves.split(" ");
    return vetorChaves
}

function generateBtn(){

    let chavesContent = chavesView.value;
    let vetKeys = inputParaVetorChaves(chavesContent);

    concatenaShapeChave(vetKeys);

    const cmdSqlCompleto = `${cmdSqlInicial}${shapeAux}${cmdSqlFinal}`;
    outputView.innerText = `${cmdSqlCompleto}`;
}

