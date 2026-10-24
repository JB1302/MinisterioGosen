document.addEventListener("DOMContentLoaded", function () {
    const form = document.getElementById("formAtenderTicket");
    const estado = document.getElementById("Estado");
    const respuesta = document.getElementById("Respuesta");
    const error = document.getElementById("errorRespuesta");

    if (!form || !estado || !respuesta || !error) {
        return;
    }

    const MENSAJE_CIERRE = "Debe registrar una respuesta para cerrar el ticket.";
    const MENSAJE_LONGITUD = "La respuesta no puede superar 500 caracteres.";

    function marcarInvalido(mensaje) {
        error.textContent = mensaje;
        respuesta.classList.add("is-invalid");
        respuesta.focus();
    }

    // Quita el error en cuanto el administrador corrige el campo o el estado.
    respuesta.addEventListener("input", function () {
        respuesta.classList.remove("is-invalid");
    });

    estado.addEventListener("change", function () {
        respuesta.classList.remove("is-invalid");
    });

    form.addEventListener("submit", function (event) {

        respuesta.classList.remove("is-invalid");

        const valor = respuesta.value.trim();

        // Para cerrar el ticket la respuesta es obligatoria.
        if (estado.value === "Cerrado" && valor === "") {
            event.preventDefault();
            marcarInvalido(MENSAJE_CIERRE);
            return;
        }

        if (valor.length > 500) {
            event.preventDefault();
            marcarInvalido(MENSAJE_LONGITUD);
        }

    });

});