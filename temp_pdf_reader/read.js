const fs = require('fs');
const pdf = require('pdf-parse');

let dataBuffer = fs.readFileSync('D:/SKRIPSIIIIIIIIIIIIIII/SUP/Naskah_Seminar_Proposal_FirdanFauzan_20220810030.pdf');

pdf(dataBuffer).then(function(data) {
    fs.writeFileSync('D:/SKRIPSIIIIIIIIIIIIIII/APLIKASI MONITORING/monitoringwaterapk/temp_pdf_reader/extracted.txt', data.text);
});
