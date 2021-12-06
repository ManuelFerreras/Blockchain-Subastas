pragma solidity >= 0.8.0;

// SPDX-License-Identifier: UNLICENSED

contract subastas_a_ciegas {

    struct subasta {
        uint256 idSubasta;
        uint256 tiempoFinSubasta;
        uint256 precioActualSubasta;
        uint256 precioInicialSubasta;
        string descripcionSubasta;
        address creadorSubasta;
        address ofertanteSubasta;
        bool estadoSubasta;
    }

    mapping(uint256 => subasta) subastas;

    uint256 contadorSubastas = 0;

    constructor() {
        // Argumentos Constructor
    }


    // Events
    event eventoSubastaCreada(uint256, uint256, string, address); // Id, Precio, Descripcion, Direccion Pagable Creador
    event eventoSubastaOfertada(uint256, uint256, address); // Id, Precio, Direccion Ofertante

    
    function crearSubasta(uint256 _precioSubasta, string memory _descripcionSubasta) public {

        // Precio a Ethers
        uint256 _precioNuevaSubasta = _precioSubasta * 1 ether;

        // Nueva Subasta.
        subasta memory _nuevaSubasta;
        _nuevaSubasta = subasta(contadorSubastas, block.timestamp + 1 hours, 0, _precioNuevaSubasta, _descripcionSubasta, msg.sender, msg.sender, true);
        subastas[contadorSubastas] = _nuevaSubasta;

        // Trigger Event.
        emit eventoSubastaCreada(contadorSubastas, _precioNuevaSubasta, _descripcionSubasta, msg.sender);

        contadorSubastas ++;

    }

    function ofertarSubasta(uint256 _idSubasta) public payable {

        // Chequeo de Condiciones.
        require(block.timestamp < subastas[_idSubasta].tiempoFinSubasta, "Esta Subasta ya ha Finalizado.");
        require(msg.sender != subastas[_idSubasta].ofertanteSubasta, "Ya eres el principal ofertante.");
        require(msg.sender != subastas[_idSubasta].creadorSubasta, "El duenio no puede ofertar.");

        uint256 _precioSubasta = conseguirPrecioSubasta(_idSubasta);
        require(msg.value > _precioSubasta, "No se ha enviado suficiente Ether.");

        // Devolver Ether al Ofertante Anterior.
        if (subastas[_idSubasta].creadorSubasta != subastas[_idSubasta].ofertanteSubasta) {
            payable(subastas[_idSubasta].ofertanteSubasta).transfer(subastas[_idSubasta].precioActualSubasta);
        }
        
        // Settear nuevo Ofertante.
        subastas[_idSubasta].precioActualSubasta = msg.value;
        subastas[_idSubasta].ofertanteSubasta = msg.sender;

        // Trigger Event.
        emit eventoSubastaOfertada(_idSubasta, msg.value, msg.sender);

    } 

    function reclamarSubasta(uint256 _idSubasta) public payable {

        require(payable(msg.sender) == subastas[_idSubasta].creadorSubasta, "Solo el creador de la subasta puede reclamarla.");
        require(block.timestamp > subastas[_idSubasta].tiempoFinSubasta, "La subasta no ha terminado aun");
        require(subastas[_idSubasta].estadoSubasta, "Subasta No Activa");

        subastas[_idSubasta].estadoSubasta = false;

        if(subastas[_idSubasta].precioActualSubasta > subastas[_idSubasta].precioInicialSubasta) {
            payable(subastas[_idSubasta].creadorSubasta).transfer(subastas[_idSubasta].precioActualSubasta);
        }

    }

    function conseguirPrecioSubasta(uint256 _idSubasta) public view returns(uint256) {
    
        return subastas[_idSubasta].precioActualSubasta > subastas[_idSubasta].precioInicialSubasta ? subastas[_idSubasta].precioActualSubasta : subastas[_idSubasta].precioInicialSubasta;

    }

}