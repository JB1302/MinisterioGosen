document.addEventListener("DOMContentLoaded", function () {

    const buscarUsuario = document.getElementById("buscarUsuario");
    const tablaUsuarios = document.getElementById("tablaUsuarios");

    if (buscarUsuario && tablaUsuarios) {

        buscarUsuario.addEventListener("keyup", function () {

            const filtro = this.value.toLowerCase();
            const filas = tablaUsuarios.querySelectorAll("tbody tr");

            filas.forEach(function (fila) {

                const texto = fila.innerText.toLowerCase();

                fila.style.display =
                    texto.includes(filtro) ? "" : "none";
            });

        });
    }

    const modalEditar = document.getElementById("modalEditar");

    if (modalEditar) {

        modalEditar.addEventListener("show.bs.modal", function (event) {

            const boton = event.relatedTarget;

            if (!boton) {
                return;
            }

            const idUsuarioMinisterio =
                document.getElementById("editarIdUsuarioMinisterio");

            const idMinisterio =
                document.getElementById("editarIdMinisterio");

            const idUsuario =
                document.getElementById("editarIdUsuario");

            const fechaIngreso =
                document.getElementById("editarFechaIngreso");

            const observacion =
                document.getElementById("editarObservacion");


            if (idUsuarioMinisterio) {
                idUsuarioMinisterio.value =
                    boton.getAttribute("data-id-usuario-ministerio") || "";
            }

            if (idMinisterio) {
                idMinisterio.value =
                    boton.getAttribute("data-id-ministerio") || "";
            }

            if (idUsuario) {
                idUsuario.value =
                    boton.getAttribute("data-id-usuario") || "";
            }

            if (fechaIngreso) {
                fechaIngreso.value =
                    boton.getAttribute("data-fecha-ingreso") || "";
            }

            if (observacion) {
                observacion.value =
                    boton.getAttribute("data-observacion") || "";
            }

        });
    }

});

function confirmarSacarUsuarioMinisterio(boton) {

    const nombre = boton.getAttribute("data-nombre");

    Swal.fire({
        title: "Confirmar eliminación",
        text: "¿Desea sacar a " + nombre + " de este ministerio?",
        icon: "warning",
        showCancelButton: true,
        confirmButtonText: "Sacar",
        cancelButtonText: "Cancelar",
        confirmButtonColor: "#dc3545",
        cancelButtonColor: "#bf8350"
    }).then(function (resultado) {

        if (resultado.isConfirmed) {

            const idUsuarioMinisterio =
                document.getElementById("sacarIdUsuarioMinisterio");

            const idMinisterio =
                document.getElementById("sacarIdMinisterio");

            const idUsuario =
                document.getElementById("sacarIdUsuario");

            const formulario =
                document.getElementById("formSacarUsuarioMinisterio");


            if (idUsuarioMinisterio) {
                idUsuarioMinisterio.value =
                    boton.getAttribute("data-id-usuario-ministerio");
            }

            if (idMinisterio) {
                idMinisterio.value =
                    boton.getAttribute("data-id-ministerio");
            }

            if (idUsuario) {
                idUsuario.value =
                    boton.getAttribute("data-id-usuario");
            }

            if (formulario) {
                formulario.submit();
            }

        }

    });
}