window.dataTableExportOptions = {
    layout: {
        topStart: {
            buttons: [
                {
                    extend: 'excelHtml5',
                    text: '<i class="bi bi-file-earmark-excel"></i> Excel',
                    customize: function (archivo) {
                        const hoja = archivo.xl.worksheets['sheet1.xml'];
                        const estilos = archivo.xl['styles.xml'];
                        const fuentes = $('fonts', estilos);
                        const rellenos = $('fills', estilos);
                        const estilosCeldas = $('cellXfs', estilos);

                        const indiceFuente = parseInt(fuentes.attr('count'), 10);
                        const indiceRelleno = parseInt(rellenos.attr('count'), 10);
                        const indiceEstilo = parseInt(estilosCeldas.attr('count'), 10);

                        fuentes.attr('count', indiceFuente + 1);
                        fuentes.append(
                            '<font>' +
                            '<sz val="11"/>' +
                            '<color rgb="FFFFFFFF"/>' +
                            '<name val="Calibri"/>' +
                            '</font>'
                        );

                        rellenos.attr('count', indiceRelleno + 1);
                        rellenos.append(
                            '<fill>' +
                            '<patternFill patternType="solid">' +
                            '<fgColor rgb="FF064442"/>' +
                            '<bgColor indexed="64"/>' +
                            '</patternFill>' +
                            '</fill>'
                        );

                        estilosCeldas.attr('count', indiceEstilo + 1);
                        estilosCeldas.append(
                            '<xf numFmtId="0" fontId="' + indiceFuente +
                            '" fillId="' + indiceRelleno +
                            '" borderId="0" applyFont="1" applyFill="1"/>'
                        );

                        $('row[r="1"] c', hoja).attr('s', indiceEstilo);
                    },
                    exportOptions: {
                        columns: function (index, data, node) {
                            return node.textContent.trim().toLowerCase() !== 'acciones';
                        }
                    }
                },
                {
                    extend: 'csv',
                    text: '<i class="bi bi-filetype-csv"></i> CSV',
                    exportOptions: {
                        columns: function (index, data, node) {
                            return node.textContent.trim().toLowerCase() !== 'acciones';
                        }
                    }
                },
                {
                    extend: 'pdfHtml5',
                    text: '<i class="bi bi-file-earmark-pdf"></i> PDF',
                    orientation: 'landscape',
                    pageSize: 'A4',
                    customize: function (documento) {
                        documento.styles.tableHeader = {
                            fillColor: '#064442',
                            color: '#ffffff',
                            bold: true,
                            alignment: 'left'
                        };
                    },
                    exportOptions: {
                        columns: function (index, data, node) {
                            return node.textContent.trim().toLowerCase() !== 'acciones';
                        }
                    }
                },
                {
                    extend: 'print',
                    text: '<i class="bi bi-printer"></i> Imprimir',
                    customize: function (ventana) {
                        $(ventana.document.head).append(
                            '<style>' +
                            'table thead th {' +
                            'background-color: #064442 !important;' +
                            'color: #ffffff !important;' +
                            'font-weight: bold !important;' +
                            '}' +
                            '</style>'
                        );
                    },
                    exportOptions: {
                        columns: function (index, data, node) {
                            return node.textContent.trim().toLowerCase() !== 'acciones';
                        }
                    }
                }
            ]
        }
    }
};
